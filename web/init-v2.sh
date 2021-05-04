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
sudo timedatectl set-timezone ${TZ:-'Europe/London'} 2>/dev/null
[ $? = 1 ] && sudo ln -sf /usr/share/zoneinfo/${TZ:-Europe/London} /etc/localtime || :
sed -i "s|.*date.timezone =.*|date.timezone = ${TZ:-'Europe/London'}|" /etc/php/${PHP_VERSION}/apache2/php.ini 2>/dev/null || sed -i "s|.*date.timezone =.*|date.timezone = ${TZ:-'Europe/London'}|" /etc/php${PHP_VERSION}/apache2/php.ini
sed -i "s|^.*date.timezone =.*|date.timezone = ${TZ:-'Europe/London'}|" /etc/php/${PHP_VERSION}/cli/php.ini 2>/dev/null || sed -i "s|^.*date.timezone =.*|date.timezone = ${TZ:-'Europe/London'}|" /etc/php${PHP_VERSION}/cli/php.ini

# Set ssh key Can be done using a secret (SSH_PRIVATE_KEY), as an ENV variable (SSH_PRIVATE_KEY)
# Or by mounting your host .ssh folder to /root/.host-ssh
# All efforts are made to avoid updating a file if it already exists - to minimise FS layers
mkdir -p /root/.ssh /tmp/.ssh
idfilecontent="Host github.com\nStrictHostKeyChecking no"
[ -d /tmp/.host-ssh ] && rsync -av --no-perms --no-owner --no-group /tmp/.host-ssh/ /root/.ssh --exclude known_hosts --delete 2>/dev/null || :
[ ! -z ${SSH_PRIVATE_KEY} ] && { echo "${SSH_PRIVATE_KEY}" >/tmp/.ssh/id_rsa && echo -e "$idfilecontent\nIdentityFile /tmp/.ssh/id_rsa" >/root/.ssh/config; } || :
[[ -f /run/secrets/SSH_PRIVATE_KEY && ! -f /tmp/.ssh/id_rsa ]] && {
  echo "USING DOCKER SECRET FOR SSH"
  cp /run/secrets/SSH_PRIVATE_KEY /tmp/.ssh/id_rsa
  echo -e "$idfilecontent\nIdentityFile /tmp/.ssh/id_rsa" >/root/.ssh/config
} || :
if ! grep -Fxq "StrictHostKeyChecking no" /root/.ssh/config 2>/dev/null; then echo -e "\n$idfilecontent\n" >>/root/.ssh/config; fi

# Set up authorised keys for SSH server (if provided)
[[ ! -z "$SSH_AUTHORIZED_KEYS" && ! -f /.authorized_keys ]] && echo "${SSH_AUTHORIZED_KEYS}" >/.authorized_keys || :
[[ -f /run/secrets/SSH_AUTHORIZED_KEYS && ! -f /.authorized_keys ]] && {
  echo "ADDING SSH AUTHORISED KEYS"
  cp /run/secrets//SSH_AUTHORIZED_KEYS /.authorized_keys
  chmod 644 /.authorized_keys
} || :

# Update file permissions to 600 for SSH files if not already correct
# Checks current permissions firs, to avoid creating unecessary extra filesystem layers
folders600=(/root/.ssh /tmp/.ssh)
for i in "${folders600[@]}"; do
  shopt -s nullglob
  for f in $(ls "$i" | sort -V); do
    if [[ $(stat -c %a "$i"/"$f") != *"600" ]]; then
      chmod 600 "$i"/"$f"
      echo updated permissions for "$i"/"$f"
    fi
  done
done

# If SSH server is enabled, start it early in the process so that it is accessible for debugging
[ "$SSH_SERVER_ENABLE" == "TRUE" ] && service ssh start

# if we have mysql installed in the same image, then start the service
[ "$LOCAL_DB" == "TRUE" ] && service mysql start

# Use docker secret as DB password, or fall back to environment variable
[ -f /run/secrets/DATABASE_PASS ] && dbpassword="$(</run/secrets/MYSQL_ROOT_PASSWORD)" || dbpassword=${MYSQL_ROOT_PASSWORD:-""}
[ ! -z $dbpassword ] && dbpassword="-p$dbpassword" || dbpassword="-p''" # Add -p to the beginning of the password (workaround for blank passwords)

# Test to see if database is accessible. If not we will rebuild it later
echo "Waiting for database server ${DATABASE_HOST:-'localhost'} (user:$MYSQL_SUPER_USER) to become available".
while ! mysqladmin ping -h"${DATABASE_HOST:-"localhost"}" -u $MYSQL_SUPER_USER "$dbpassword" --silent; do
  sleep 1
  echo -n "." # keep adding dots until connected
done
echo Testing Database: host=${DATABASE_HOST:-"localhost"} user=${MYSQL_SUPER_USER:-"openeyes"} name=${DATABASE_NAME:-"openeyes"}...

# NOTE: The $? on the end of the next line is very important - it converts the output to a 1 or 0
db_pre_exist=$(! mysql --host=${DATABASE_HOST:-'localhost'} -u $MYSQL_SUPER_USER "$dbpassword" -e "use ${DATABASE_NAME:-'openeyes'};" 2>/dev/null)$?

[ "$db_pre_exist" = "1" ] && echo "...database ${DATABASE_NAME:-'openeyes'} found." || echo "...could not find database ${DATABASE_NAME:-'openeyes'}. It will be (re) created..."

newinstall=0

# If no web files exist, check them out locally
if [ ! -f $WROOT/protected/config/core/common.php ]; then
  ssh git@github.com -T
  [ "$?" == "1" ] && cloneroot="git@github.com:" || cloneroot="https://github.com/"
  # If GIT_ORG is not specified then - If using https we defualt to appertafoundation. If ussing ssh we default to openeyes
  [ -z "$GIT_ORG" ] && { [ "$cloneroot" == "https://github.com/" ] && gitroot="appertafoundation" || gitroot="openeyes"; } || gitroot=$GIT_ORG

  # If openeyes files don't already exist then clone them
  echo cloning "-b ${BUILD_BRANCH} $cloneroot${gitroot}/openeyes.git"
  git clone -b ${BUILD_BRANCH} $cloneroot${gitroot}/openeyes.git $WROOT

  newinstall=1
fi

# If this is a new container (using existing git files), then we need to initialise the config

if [ ! -f /initialised.oe ]; then

  ## Override default protected files folder with mounted folder, if it exists
  ## This only runs on container initialisation, and will be skipped if the symlink alrady exists (-L checks if it is a symlink)
  if [[ -d "/protected/files" && ! -L $WROOT/protected/files ]]; then
    mkdir -p $WROOT/protected/ 2>/dev/null
    # Check if there are already any sub-folders in $WROOT/protected/files - if so we should not overwrite them!
    # if [ $(ls -l "$WROOT/protected/files" | grep -c ^d) -gt 0 ]; then
    #   echo -e "CANNOT MAP YOUR protected/files volume, as $WROOT/protected/files folder already exists. Remove this folder first, then try again\nEXITING..."
    #   exit 1
    # else
    echo -e "Mapping /protected/files into protected directory..\n"
    # fi
    # We have to delete the files folder if it already exists, as a symlink cannot overwrite an existing folder
    rm -rf "$WROOT/protected/files" 2>/dev/null
    chmod -R 775 /protected/files
    ln -sf /protected/files $WROOT/protected
    # re-add .gitignore, as it will have been overwritten when mounting the volume. Otjerwise everthing in protected/files gets comitted to github!
    [ ! -f "$WROOT/protected/files/.gitignore" ] && echo -e "# Ignore everything in this directory\n*\n# Except this file\n!.gitignore\n" >"$WROOT"/protected/files/.gitignore || :
  fi

  initparams="$BUILD_BRANCH --accept --no-migrate --preserve-database --no-sample"
  [[ $newinstall = 0 && -d "$WROOT/protected/modules/eyedraw/src" ]] && initparams="$initparams --no-checkout" || :
  echo "Initialising new container..."
  # $WROOT/protected/scripts/install-oe.sh $initparams
  # oe-fix
  echo "true" >/initialised.oe
fi

# if [ "$db_pre_exist" != "1" ]; then
#     #If DB doesn't exist then create it - if ENV sample=demo, etc, then call oe-reset (--demo) --no-dependencies --no-migrate
#     echo "Database host=${DATABASE_HOST:-'localhost'}; user=${MYSQL_SUPER_USER:-'openeyes'}; name=${DATABASE_NAME:-'openeyes'} was not fount. Creating a new db"
#     [ "$USE_DEMO_DATA" = "TRUE" ] && resetparams="--demo" || resetparams=""
#     oe-reset -b $BUILD_BRANCH $resetparams
# fi

[[ ! -d "$WROOT/node_modules" || ! -d "$WROOT/vendor/yiisoft" ]] && {
  echo -e "\n\nDependencies not found, installing now...\n\n"
  $WROOT/protected/scripts/oe-fix.sh
} || :

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

[[ -z $(git config --global user.name) && ! -z $GIT_USER ]] && { git config --global user.name "$GIT_USER" && echo "git global user set to $GIT_USER"; } || :
[[ -z $(git config --global user.email) && ! -z $GIT_EMAIL ]] && { git config --global user.email "$GIT_EMAIL" && echo "git global email set to $GIT_EMAIL"; } || :

if [ "${TRACK_NEW_GIT_COMMITS^^}" == "TRUE" ]; then
  echo ""
  echo "************************************************************************"
  echo "** -= This container automatically pulls from git every 30 minutes =- **"
  echo "************************************************************************"

  [ ! -f /etc/cron.d/track_git ] && echo -e "# /etc/cron.d/track_git: Update to latest git code every 30 minutes\n*/30 * * * *   root . /env.sh; /var/www/openeyes/protected/scripts/oe-update.sh -f >/dev/null 2>&1" >/etc/cron.d/track_git | :

fi

$WROOT/protected/scripts/set-profile.sh

[[ "$OE_PORTAL_ENABLED" = "TRUE" && ! -f /etc/cron.d/portalexams ]] && {
  echo "*/5  * * * *  root  . /env.sh; /var/www/openeyes/protected/yiic portalexams >> $WROOT/protected/runtime/portalexams.log 2>&1" >/etc/cron.d/portalexams
  chmod 0644 /etc/cron.d/portalexams
} | :

# store environment to file - needed for cron jobs
[ ! -f /env.sh ] && { env | sed -r "s/'/\\\'/gm" | sed -r "s/^([^=]+=)(.*)\$/export \1'\2'/gm" >/env.sh; } || :

# start cron (needed for hotlist updates + other tasks depending on configuration)
service cron start

# Start apache
echo "Starting opeyes apache process..."
echo "openeyes should now be available in your web browser on your chosen port."

#service apache2 start

echo ""
echo "*********************************************"
echo "**       -= END OF STARTUP SCRIPT =-       **"
echo "*********************************************"
# Send output of openeyeyes application log to stdout - for viewing with docker logs
[ ! -f $WROOT/protected/runtime/application.log ] && {
  touch $WROOT/protected/runtime/application.log
  chmod 664 $WROOT/protected/runtime/application.log
} | :
[ ! -f $WROOT/protected/runtime/portalexams.log ] && {
  touch $WROOT/protected/runtime/portalexams.log
  chmod 664 $WROOT/protected/runtime/portalexams.log
} | :
tail -n0 $WROOT/protected/runtime/application.log -F | awk '/^==> / {a=substr($0, 5, length-8); next} {print a"App Log:"$0}' &
tail -n0 $WROOT/protected/runtime/portalexams.log -F | awk '/^==> / {a=substr($0, 5, length-8); next} {print a"Portal Log:"$0}' &

apachectl -DFOREGROUND
