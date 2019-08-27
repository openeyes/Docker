#!/bin/bash -l

echo "

----------------------------------------------------------------
   ____                   ______
  / __ \                 |  ____|
 | |  | |_ __   ___ _ __ | |__  _   _  ___  ___
 | |  | | '_ \ / _ \ '_ \|  __|| | | |/ _ \/ __|
 | |__| | |_) |  __/ | | | |___| |_| |  __/\__ \.
  \____/| .__/ \___|_| |_|______\__, |\___||___/
        | |                      __/ |
        |_|                     |___/

Openeyes is an AGPL v3 OpenSource Electronic Patient Record.
Brought to you by the Apperta Foundation (https://apperta.org/)
See the following urls for more info
- https://openeyes.org.uk/
- https://github.com/openeyes/openeyes
- https://github.com/appertafoundation/openeyes

----------------------------------------------------------------

"
export DEBIAN_FRONTEND=noninteractive

echo "Setting Timezone to ${TZ:-'Europe/London'}"
# Set system timezone
grep -q "$TZ" /etc/timezone >/dev/null
[ $? = 1 ] && { ln -sf /usr/share/zoneinfo/${TZ:-Europe/London} /etc/localtime && echo ${TZ:-'Europe/London'} > /etc/timezone; } || :
# set PHP/apache timezone (only if changed - to avoid unnecessary extra file layers)
grep -q "$TZ" /etc/php/${PHP_VERSION}/apache2/conf.d/99-timezone.ini >/dev/null
[ $? = 1 ] && { echo "date.timezone = ${TZ:-'Europe/London'}" > /etc/php/${PHP_VERSION}/apache2/conf.d/99-timezone.ini && echo "Updated 99-timezone.ini"; } | :

# set any new PHP ini settings from PHPI_* environment variables
/set_php_vars.sh

# Set ssh key Can be done using a secret (SSH_PRIVATE_KEY), as an ENV variable (SSH_PRIVATE_KEY)
# Or by mounting your host .ssh folder to /root/.host-ssh
# All efforts are made to avoid updating a file if it already exists - to minimise FS layers
mkdir -p /root/.ssh /tmp/.ssh
idfilecontent="Host github.com\nStrictHostKeyChecking no"
[ -d /tmp/.host-ssh ] && rsync -av --no-perms --no-owner --no-group /tmp/.host-ssh/ /root/.ssh --exclude known_hosts --delete 2>/dev/null || :
[ ! -z ${SSH_PRIVATE_KEY} ] && { echo "${SSH_PRIVATE_KEY}" > /tmp/.ssh/id_rsa && echo -e "$idfilecontent\nIdentityFile /tmp/.ssh/id_rsa" > /root/.ssh/config; } || :
[[ -f /run/secrets/SSH_PRIVATE_KEY && ! -f /tmp/.ssh/id_rsa ]] && { echo "USING DOCKER SECRET FOR SSH"; cp /run/secrets/SSH_PRIVATE_KEY /tmp/.ssh/id_rsa; echo -e "$idfilecontent\nIdentityFile /tmp/.ssh/id_rsa" > /root/.ssh/config ; } || :
if ! grep -Fxq "StrictHostKeyChecking no" /root/.ssh/config 2>/dev/null; then echo -e "\n$idfilecontent\n" >> /root/.ssh/config; fi

# Set up authorised keys for SSH server (if provided)
[[ ! -z "$SSH_AUTHORIZED_KEYS" && ! -f ~/.ssh/authorized_keys ]] && echo "${SSH_AUTHORIZED_KEYS}" > ~/.ssh/authorized_keys || :
[[ -f /run/secrets/SSH_AUTHORIZED_KEYS && ! -f ~/.ssh/authorized_keys ]] && { echo "ADDING SSH AUTHORISED KEYS"; cp /run/secrets//SSH_AUTHORIZED_KEYS ~/.ssh/authorized_keys; chmod 644 ~/.ssh/authorized_keys ; } || :

# Update file permissions to 600 for SSH files if not already correct
# Checks current permissions firs, to avoid creating unecessary extra filesystem layers
folders600=( /root/.ssh /tmp/.ssh )
for i in "${folders600[@]}"
do
  shopt -s nullglob
  for f in $(ls "$i" | sort -V)
  do
      if [[ $(stat -c %a "$i"/"$f") != *"600" ]]; then
        chmod 600 "$i"/"$f"
        echo updated permissions for "$i"/"$f"
      fi
  done
done

# If SSH server is enabled, start it early in the process so that it is accessible for debugging
[ "${SSH_SERVER_ENABLE^^}" == "TRUE" ] && service ssh start

# if we have mysql installed in the same image, then start the service
[ "${LOCAL_DB^^}" == "TRUE" ] && service mysql start

# Use docker secret as DB password, or fall back to environment variable
[ -f /run/secrets/DATABASE_PASS ] && dbpassword="$(</run/secrets/DATABASE_PASS)" || dbpassword=${DATABASE_PASS:-""}
[ ! -z $dbpassword ] && dbpassword="-p$dbpassword" || dbpassword="-p''" # Add -p to the beginning of the password (workaround for blank passwords)

# Test to see if database and other hosts are available before continuing.
# hosts can be specified as an environment variable WAIT_HOSTS with a comma separated list of host:port pairs to wait for
# The wait command is from https://github.com/ufoscout/docker-compose-wait
# The following additional options are available:
#  # WAIT_HOSTS: comma separated list of pairs host:port for which you want to wait.
#  # WAIT_HOSTS_TIMEOUT: max number of seconds to wait for the hosts to be available before failure. The default is 30 seconds.
#  # WAIT_BEFORE_HOSTS: number of seconds to wait (sleep) before start checking for the hosts availability
#  # WAIT_AFTER_HOSTS: number of seconds to wait (sleep) once all the hosts are available
#  # WAIT_SLEEP_INTERVAL: number of seconds to sleep between retries. The default is 1 second.
# Note that we always add the database server to the list
[ -z $WAIT_HOSTS ] && export WAIT_HOSTS="${DATABASE_HOST:-'localhost'}:${DATABASE_PORT:-'3306'}" || export WAIT_HOSTS="${DATABASE_HOST:-'localhost'}:${DATABASE_PORT:-'3306'},$WAIT_HOSTS"
echo "Waitng for host dependencies to become available..."
if ! /wait = 1; then 
  echo "Not all dependent hosts were contactable. Exiting."
  exit; 
fi

# Test to see if database exists - if not we will (re)build it later
echo Testing Database: host=${DATABASE_HOST:-"localhost"} user=${DATABASE_USER:-"openeyes"} name=${DATABASE_NAME:-"openeyes"}...

# NOTE: The $? on the end of the next line is very important - it converts the output to a 1 or 0
db_pre_exist=$( ! mysql -A --host=${DATABASE_HOST:-'localhost'} -u $DATABASE_USER "$dbpassword" -e "use ${DATABASE_NAME:-'openeyes'};" 2>/dev/null)$?

[ "$db_pre_exist" = "1" ] && echo "...database ${DATABASE_NAME:-'openeyes'} found." || echo "...could not find database ${DATABASE_NAME:-'openeyes'}. It will be (re) created..."

newinstall=0

cloneswitches=""
# If we are in test mode, only do a shallow clone
[ "${OE_MODE^^}" = "TEST" ] && cloneswitches="--single-branch --depth 1 $cloneswitches"

# If no web files exist, check them out locally
if [ ! -f $WROOT/protected/config/core/common.php ]; then
  ssh git@github.com -T
  [ "$?" == "1" ] && cloneroot="git@github.com:" || cloneroot="https://github.com/"
  # If GIT_ORG is not specified then - If using https we defualt to appertafoundation. If ussing ssh we default to openeyes
  [ -z "$GIT_ORG" ] && { [ "$cloneroot" == "https://github.com/" ] && gitroot="appertafoundation" || gitroot="openeyes";} || gitroot=$GIT_ORG

  # If openeyes files don't already exist then clone them
  echo cloning "$cloneswitches $cloneroot${gitroot}/openeyes.git"
  git clone -b ${BUILD_BRANCH} $cloneswitches $cloneroot${gitroot}/openeyes.git $WROOT

  newinstall=1
fi

# If this is a new container (using existing git files), then we need to initialise the config

if [ ! -f /initialised.oe ]; then
  initparams="${BUILD_BRANCH} $cloneswitches --accept --no-migrate --preserve-database --no-sample"
  [[ $newinstall = 0 && -d "$WROOT/protected/modules/eyedraw/src" ]] && initparams="$initparams --no-checkout" || :
  echo "Initialising new container..."
  $WROOT/protected/scripts/install-oe.sh $initparams

  if [ "$db_pre_exist" != "1" ] || [ "${OE_FORCE_DB_RESET^^}" = "TRUE" ]; then
    #If DB doesn't exist then create it - if ENV sample=demo, etc, then call oe-reset (--demo) --no-dependencies --no-migrate
    echo "Database host=${DATABASE_HOST:-'localhost'}; user=${MYSQL_SUPER_USER:-'openeyes'}; name=${DATABASE_NAME:-'openeyes'} was not fount. Creating a new db"
    [ "${USE_DEMO_DATA^^}" = "TRUE" ] && resetparams="--demo" || resetparams=""
    $WROOT/protected/scripts/oe-reset.sh -b $BUILD_BRANCH $resetparams
  fi
  
fi

# If the database pre-existed AND we are in test mode, then automatically run the latest migrations
# Or also if OE_FORCE_MIGRATE=TRUE then force the migration
[ "$db_pre_exist" = "1" ] && { [[ "${OE_MODE^^}" = "TEST" || "${OE_FORCE_MIGRATE^^}" = "TRUE" ]] && $WROOT/protected/scripts/oe-migrate.sh -q || : ; } || :

[[ ! -d "$WROOT/node_modules" || ! -d "$WROOT/vendor/yiisoft" ]] && { echo -e "\n\nDependencies not found, installing now...\n\n"; $WROOT/protected/scripts/oe-fix.sh; } || :

# Ensure .htaccess is set
if [ ! -f "$WROOT/.htaccess" ]; then
    echo Copying .htaccess file
    cp $WROOT/.htaccess.sample $WROOT/.htaccess
    sudo chown www-data:www-data $WROOT/.htaccess
fi

# ensure index is set
if [ ! -f "$WROOT/index.php" ]; then
    echo Copying index.php file
    cp $WROOT/index.example.php $WROOT/index.php
    sudo chown www-data:www-data $WROOT/index.php
fi


# Set github user and email config (if provided)
[[ -z $(git config --global user.name)  && ! -z $GIT_USER ]] && { git config --global user.name "$GIT_USER" && echo "git global user set to $(git config --global user.name)"; } || :
if [[ -z $(git config --global user.email) && ! -z $GIT_USER ]]; then
  # if an email has been explicitly provided, use it. Else use default gitbug no reply user address
  if [ ! -z $GIT_EMAIL ]; then 
    git config --global user.email "$GIT_EMAIL"
  else
    git config --global user.email "${GIT_USER}@users.noreply.github.com"
  fi 
  echo "git global email set to $(git config --global user.email)"
fi

if [ "${TRACK_NEW_GIT_COMMITS^^}" == "TRUE" ]; then
  echo ""
  echo "************************************************************************"
  echo "** -= This container automatically pulls from git every 30 minutes =- **"
  echo "************************************************************************"

  [ ! -f /etc/cron.d/track_git ] && echo -e "# /etc/cron.d/track_git: Update to latest git code every 30 minutes\n*/30 * * * *   root . /env.sh; /var/www/openeyes/protected/scripts/oe-update.sh -f >/dev/null 2>&1" > /etc/cron.d/track_git | :

fi

# Set BEHAT default behat paramerters for BEHAT testing
[ -z $BEHAT_PARAMS ] && export BEHAT_PARAMS="extensions[Behat\\MinkExtension\\Extension][base_url]=${SELENIUM_BASE_URL:-http://host.docker.internal}&extensions[Behat\\MinkExtension\\Extension][selenium2][wd_host]=${SELENIUM_WD_HOST:-http://host.docker.internal:4444/wd/hub}" || :

# update profile shortcuts
$WROOT/protected/scripts/set-profile.sh

[[ "${OE_PORTAL_ENABLED^^}" = "TRUE" && ! -f /etc/cron.d/portalexams ]] && { echo "*/5  * * * *  root  . /env.sh; /var/www/openeyes/protected/yiic portalexams >> $WROOT/protected/runtime/portalexams.log 2>&1" > /etc/cron.d/portalexams; chmod 0644 /etc/cron.d/portalexams; } | :

# store environment to file - needed for cron jobs
if [ ! -f "/env.sh" ]; then 
  env | sed -r "s/'/\\\'/gm" | sed -r "s/^([^=]+=)(.*)\$/export \1'\2'/gm" > /env.sh; chmod a+x /env.sh
  # Remove some unwanted env settings (these can confuse other system behaviour if left in)
  sed -i -E '/\sPATH=|\s_=|\sSHLVL=|\sTERM=|\sPWD=|\sDEBIAN_/d' /env.sh
fi


[ ! -f /initialised.oe ] && echo "true" > /initialised.oe || :

# start cron (needed for hotlist updates + other tasks depending on configuration)
service cron start

# Start apache
echo "Starting opeyes apache process..."
echo "openeyes should now be available in your web browser on your chosen port."
echo ""
echo "*********************************************"
echo "**       -= END OF STARTUP SCRIPT =-       **"
echo "*********************************************"
# Send output of openeyeyes application log to stdout - for viewing with docker logs
[ ! -f $WROOT/protected/runtime/application.log ] && { touch $WROOT/protected/runtime/application.log; chmod 664 $WROOT/protected/runtime/application.log; } | :
[ ! -f $WROOT/protected/runtime/portalexams.log ] && { touch $WROOT/protected/runtime/portalexams.log; chmod 664 $WROOT/protected/runtime/portalexams.log; } | :
[ ! -f /var/log/php_errors.log ] && { touch /var/log/php_errors.log; chmod 664 /var/log/php_errors.log; } | :
tail -n0 $WROOT/protected/runtime/application.log -F | awk '/^==> / {a=substr($0, 5, length-8); next} {print a"App Log:"$0}' &
tail -n0 $WROOT/protected/runtime/portalexams.log -F | awk '/^==> / {a=substr($0, 5, length-8); next} {print a"Portal Log:"$0}' &
tail -n0 /var/log/php_errors.log -F | awk '/^==> / {a=substr($0, 5, length-8); next} {print a"PHP Log:"$0}' &

# note - the ^^ converts to uppercase (,, can be used to convert to lowercase)
if [ ${OE_MODE^^} = "TEST" ]; then 
  ## TESTS_TO_RUN is a semi-colon separated list of tests
  [ ! -z "$TESTS_TO_RUN" ] && { IFS=';' read -ra tests <<< "$TESTS_TO_RUN"; echo "Will auto-run the following test(s): ${tests[@]}"; } || echo "Tests will not run automatically. To auto-start tests, set the TESTS_TO_RUN env variable (space separated list)"

  # If tests are specified, run them automatically. Else, continue as normal
  if [ "${#tests[@]}" -gt 0 ]; then 
    echo "STARING TESTS..."
  
    result=0

    for i in "${!tests[@]}"
    do
      lastresult=-1

        if [ "${tests[i]^^}" = "PHPUNIT" ]; then
          echo "*** RUNNING PHPUNIT ***" 
          [ ! -z ${PHPUNIT_CLI_SWITCHES} ] && echo " With extra switches: ${PHPUNIT_CLI_SWITCHES}"
          $WROOT/protected/scripts/oe-unit-tests.sh ${PHPUNIT_CLI_SWITCHES}
          lastresult=$?
        elif [ "${tests[i]^^}" = "BEHAT" ]; then
          echo "*** RUNNING BEHAT ***" 
          service apache2 start
          $WROOT/protected/scripts/oe-behat-tests.sh${BEHAT_CONFIG_PATH:+ --config $BEHAT_CONFIG_PATH}${BEHAT_CLI_SWITCHES:+ $BEHAT_CLI_SWITCHES}${BEHAT_TEST_PATH:+ --test $BEHAT_TEST_PATH}
          lastresult=$?
          service apache2 stop 2>/dev/null
        else
          echo "*** ERROR: Test '${tests[i]^^}' from TESTS_TO_RUN was not recognised. Skipping. ****"
        fi

        echo Test Result = $lastresult
        # If any test fails then the final result will = the first error code
        [ $lastresult -gt 0 ] && result=$lastresult || :

        # if this is not the last test, then restet the database
      [[ $((i + 1)) -lt ${#tests[@]} && -z $NO_RESET_DB_BETWEEN_TESTS ]] && { echo -e "\n\n\n ********** RESETTING DATABASE **********\n\n\n"; $WROOT/protected/scripts/oe-reset.sh -b $BUILD_BRANCH; } || :
      
    done
    echo Final result of all tests = $result
    exit $result;
  fi
fi

apachectl -DFOREGROUND

