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

****************************************************************
**************       DICOM Processor Service      **************
****************************************************************

DATABASE_HOST= $DATABASE_HOST:$DATABASE_PORT
DATABASE_USER= $DATABASE_USER
DATABASE_NAME= $DATABASE_NAME

***************************************************************

"
export DEBIAN_FRONTEND=noninteractive

echo "Setting Timezone to ${TZ:-'Europe/London'}"
# Set system timezone
grep -q "$TZ" /etc/timezone >/dev/null
[ $? = 1 ] && { ln -sf /usr/share/zoneinfo/${TZ:-Europe/London} /etc/localtime && echo ${TZ:-'Europe/London'} > /etc/timezone; } || :
# set PHP/apache timezone (only if changed - to avoid unnecessary extra file layers)
grep -q "$TZ" /etc/php/${PHP_VERSION}/apache2/conf.d/99-timezone.ini >/dev/null
[ $? = 1 ] && { echo "date.timezone = ${TZ:-'Europe/London'}" > /etc/php/${PHP_VERSION}/apache2/conf.d/99-timezone.ini && echo "Updated 99-timezone.ini"; } | :

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
[ "$SSH_SERVER_ENABLE" == "TRUE" ] && service ssh start

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

# Test to see if database exists - if not we will quit
# NOTE: It is recommended to add a WAIT_HOSTS for the web server to be active first, as this will ensure the database is built
echo Testing Database: host=${DATABASE_HOST:-"localhost"} user=${DATABSE_USER:-"openeyes"} name=${DATABASE_NAME:-"openeyes"}...

# NOTE: The $? on the end of the next line is very important - it converts the output to a 1 or 0
db_pre_exist=$( ! mysql -A --host=${DATABASE_HOST:-'localhost'} -u $DATABASE_USER "$dbpassword" -e "use ${DATABASE_NAME:-'openeyes'};" 2>/dev/null)$?

[ "$db_pre_exist" = "1" ] && echo "...database ${DATABASE_NAME:-'openeyes'} found." || { echo "...could not find database ${DATABASE_NAME:-'openeyes'}. Quitting..."; exit 1; }


switches="-sf $PROJROOT/src/main/resources/routineLibrary/ -rq dicom_queue -sy 99999"

# If a shutdown after (minutes) has been specified, then pass this to the processor. It will then run for x minutes before automatically shutting down
[ $PROCESSOR_SHUTDOWN_AFTER -gt 0 ] && switches="$switches -sa $PROCESSOR_SHUTDOWN_AFTER" || :

# Start apache
echo "Starting opeyes DicomProcessor process..."
echo ""
echo "*********************************************"
echo "**       -= END OF STARTUP SCRIPT =-       **"
echo "*********************************************"
# Send output of openeyeyes application log to stdout - for viewing with docker logs
# touch $PROJROOT/protected/runtime/application.log
# chmod 664 $PROJROOT/protected/runtime/application.log
# tail -n0 $PROJROOT/protected/runtime/application.log -F | awk '/^==> / {a=substr($0, 5, length-8); next} {print a"App Log:"$0}' &

$PROJROOT/target/appassembler/bin/dicomEngine $switches
