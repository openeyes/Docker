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
sudo timedatectl set-timezone ${TZ:-'Europe/London'} 2>/dev/null
[ $? = 1 ] && sudo ln -sf /usr/share/zoneinfo/${TZ:-Europe/London} /etc/localtime || :

# Set ssh key Can be done using a secret (SSH_PRIVATE_KEY), as an ENV variable (SSH_PRIVATE_KEY)
# Or by mounting your host .ssh folder to /root/.host-ssh
# mkdir -p /root/.ssh /tmp/.ssh
# idfilecontent="Host github.com\nStrictHostKeyChecking no"
# [ -d /tmp/.host-ssh ] && rsync -av /tmp/.host-ssh/ /root/.ssh --exclude known_hosts --delete 2>/dev/null || :
# [ ! -z ${SSH_PRIVATE_KEY} ] && { echo "${SSH_PRIVATE_KEY}" > /tmp/.ssh/id_rsa && echo -e "$idfilecontent\nIdentityFile /tmp/.ssh/id_rsa" > /root/.ssh/config; } || :
# [ -f /run/secrets/SSH_PRIVATE_KEY ] && { echo "USING DOCKER SECRET FOR SSH"; cp /run/secrets/SSH_PRIVATE_KEY /tmp/.ssh/id_rsa; echo -e "$idfilecontent\nIdentityFile /tmp/.ssh/id_rsa" > /root/.ssh/config ; } || :
# if ! grep -Fxq "StrictHostKeyChecking no" /root/.ssh/config; then echo -e "\n$idfilecontent\n" >> /root/.ssh/config; fi
# [ -d /root/.ssh ] && chmod 600 /root/.ssh/* || :
# [ -d /tmp/.ssh ] && chmod 600 /tmp/.ssh/* || :

# Use docker secret as DB password, or fall back to environment variable
[ -f /run/secrets/DATABASE_PASS ] && dbpassword="$(</run/secrets/MYSQL_ROOT_PASSWORD)" || dbpassword=${MYSQL_ROOT_PASSWORD:-""}
[ ! -z $dbpassword ] && dbpassword="-p$dbpassword" || dbpassword="-p''" # Add -p to the beginning of the password (workaround for blank passwords)

# Test to see if database is accessible. If not we will rebuild it later
echo "Waiting for $maxcounter seconds for database server ${DATABASE_HOST:-'localhost'} (user:$MYSQL_SUPER_USER) to become available".
while ! mysqladmin ping -h"${DATABASE_HOST:-"localhost"}" -u $MYSQL_SUPER_USER "$dbpassword" --silent; do
    sleep 1
    echo -n "." # keep adding dots until connected
done

# If no project files exist, check them out locally
# if [ ! -d $PROJROOT/bin/src/main/java/com/abehrdigital/dicomprocessor/DicomParser.class ]; then
#   ssh git@github.com -T
#   [ "$?" == "1" ] && cloneroot="git@github.com:" || cloneroot="https://github.com/"
#   # If GIT_ORG is not specified then - If using https we defualt to appertafoundation. If ussing ssh we default to openeyes
#   [ -z "$GIT_ORG" ] && { [ "$cloneroot" == "https://github.com/" ] && gitroot="appertafoundation" || gitroot="openeyes";} || gitroot=$GIT_ORG
#
#   echo cloning "-b ${BUILD_BRANCH} $cloneroot${gitroot}/DicomProcessor.git"
#   git clone -b ${BUILD_BRANCH} $cloneroot${gitroot}/DicomProcessor.git $PROJROOT
#
# fi

# If container is not already initialised then run the mavern package to build project + dependencies
# if [ ! -f /initialised.oe ]; then
#     cd $PROJROOT
#     mvn package
#     echo "true" > /initialised.oe
# fi


[[ -z $(git config --global user.name)  && ! -z $GIT_USER ]] && { git config --global user.name "$GIT_USER" && echo "git global user set to $GIT_USER"; } || :
[[ -z $(git config --global user.email) && ! -z $GIT_EMAIL ]] && { git config --global user.email "$GIT_EMAIL" && echo "git global email set to $GIT_EMAIL"; } || :

# if [ "${TRACK_NEW_GIT_COMMITS^^}" == "TRUE" ]; then
#   echo ""
#   echo "************************************************************************"
#   echo "** -= This container automatically pulls from git every 30 minutes =- **"
#   echo "************************************************************************"
#
#   [ ! -f /etc/cron.d/track_git ] && echo -e "# /etc/cron.d/track_git: Update to latest git code every 30 minutes\n*/30 * * * *   root  /var/www/openeyes/protected/scripts/oe-update.sh -f >/dev/null 2>&1" > /etc/cron.d/track_git | :
#
# fi

switches="-sf $PROJROOT/src/main/resources/routineLibrary/ -rq dicom_queue -sy 99999"

# If a shutdown after (minutes) has been specified, then pass this to the processor. It will then run for x minutes before automatically shutting down
[ $PROCESSOR_SHUTDOWN_AFTER > 0 ] && switches="$switches -sa $PROCESSOR_SHUTDOWN_AFTER" || :

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
sleep 1h
