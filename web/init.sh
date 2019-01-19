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

# if we have mysql installed in the same image, then start the service
[ "$LOCAL_DB" == "TRUE" ] && service mysql start

# Set ssh key Can be done using a secret (ssh_key), as an ENV variable (SSH_PRIVATE_KEY)
# Or by mounting your host .ssh folder to /root/.host-ssh
mkdir -p /root/.ssh
idfilecontent="Host github.com\nStrictHostKeyChecking no"
[ -d /root/.host-ssh ] && rsync -av /root/.host-ssh /root/.ssh --exclude known_hosts --delete 2>/dev/null
[ ! -z ${SSH_PRIVATE_KEY} ] && { echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && echo -e "$idfilecontent\nIdentityFile ~/.ssh/id_rsa" > /root/.ssh/config; }
[ -f /run/secrets/ssh_key ] && { cp /run/secrets/ssh_key /root/.ssh/id_rsa; echo -e "$idfilecontent\nIdentityFile ~/.ssh/id_rsa" > /root/.ssh/config ; }
chmod 600 /root/.ssh/*

# If no web files exist, check them out locally
if [ ! -d /openeyes/protected ]; then
  ssh git@github.com -T
  [ "$?" == "1" ] && cloneroot="git@github.com:" || cloneroot="https://"
  [ -z "$GIT_ORG" ] && { [ "$cloneroot" == "https://" ] && gitroot="appertafoundation" || gitroot="openeyes";} || gitroot=$GIT_ORG
echo cloning "-b ${BUILD_BRANCH} $cloneroot${gitroot}/openeyes.git"
  git clone --depth=1 -b ${BUILD_BRANCH} $cloneroot${gitroot}/openeyes.git /openeyes
  /openeyes/protected/scripts/oe-checkout.sh ${BUILD_BRANCH} --no-fix -no-oe

fi

# Ensure .htaccess is set
if [ ! -f "/openeyes/.htaccess" ]; then
    echo Renaming .htaccess file
    mv /openeyes/.htaccess.sample /openeyes/.htaccess
    sudo chown www-data:www-data /openeyes/.htaccess
fi

# ensure index is set
if [ ! -f "/openeyes/index.php" ]; then
    echo Renaming index.php file
    mv /openeyes/index.example.php /openeyes/index.php
    sudo chown www-data:www-data /openeyes/index.php
fi

/openeyes/protected/scripts/set-profile.sh

# Use docker secret as DB password, or fall back to environment variable
[ -f /run/secrets/DATABASE_PASS ] && dbpassword="$(</run/secrets/MYSQL_ROOT_PASSWORD)" || dbpassword=${MYSQL_ROOT_PASSWORD:-""}
[ ! -z $dbpassword ] && dbpassword="-p$dbpassword" || dbpassword="-p''" # Add -p to the beginning of the password (workaround for blank passwords)

echo Testing Database: host=${DATABASE_HOST:-"localhost"} user=${MYSQL_SUPER_USER:-"openeyes"} password="$dbpassword" name=${DATABASE_NAME:-"openeyes"}

mysql --host=${DATABASE_HOST:-'localhost'} -u $MYSQL_SUPER_USER "$dbpassword" -e 'use '"${DATABASE_NAME:-'openeyes'};"

if [ $? != "0" ]; then
    #If DB doesn't exist then create it - if ENV sample=demo, etc, then call oe-reset (--demo) --no-dependencies --no-migrate
    echo "Database host=${DATABASE_HOST:-'localhost'}; user=${MYSQL_SUPER_USER:-'openeyes'}; name=${DATABASE_NAME:-'openeyes'} was not fount. Creating a new db"
    [ "$USE_DEMO_DATA" = "TRUE" ] && resetparams="--demo" || resetparams=""
    /openeyes/protected/scripts/oe-reset.sh -b $BUILD_BRANCH $resetparams
fi

[[ ! -d "/openeyes/node_modules" || ! -d "/openeyes/vendor/yiisoft" ]] && /openeyes/protected/scripts/oe-fix.sh || :

# Start apache
apachectl -DFOREGROUND
