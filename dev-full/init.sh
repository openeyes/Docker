#!/bin/bash

echo "

----------------------------------------------------------------
   ____                   ______
  / __ \                 |  ____|
 | |  | |_ __   ___ _ __ | |__  _   _  ___  ___
 | |  | | '_ \ / _ \ '_ \|  __|| | | |/ _ \/ __|
 | |__| | |_) |  __/ | | | |___| |_| |  __/\__ \ 
  \____/| .__/ \___|_| |_|______\__, |\___||___/
        | |                      __/ |
        |_|                     |___/

Openeyes is an AGPL OpenSource Electronic Patient Record.
Brought to you by the Apperta Foundation (https://apperta.org/)
See the following urls for more info
- https://openeyes.org.uk/
- https://github.com/openeyes/openeyes
- https://github.com/appertafoundation/openeyes

----------------------------------------------------------------

"

WROOT="/var/www/html"

# Set ssh key - requires mounting hosts .ssh folder to /root/.host-ssh
mkdir -p /root/.ssh
rsync -av /root/.host-ssh /root/.ssh --exclude known_hosts --delete 2>/dev/null
chmod 600 /root/.ssh/*


# Ensure .htaccess is set
if [ ! -f "$WROOT/.htaccess" ]; then
    echo Renaming .htaccess file
    mv $WROOT/.htaccess.sample $WROOT/.htaccess
    sudo chown www-data:www-data $WROOT/.htaccess
fi

# ensure index is set
if [ ! -f "$WROOT/index.php" ]; then
    echo Renaming index.php file
    mv $WROOT/index.example.php $WROOT/index.php
    sudo chown www-data:www-data $WROOT/index.php
fi

if [ ! -f "$WROOT/protected/config/local/common.php" ]; then

        echo "WARNING: Copying sample configuration into local ..."
                sudo mkdir -p $WROOT/protected/config/local
                sudo cp -n $WROOT/protected/config/local.sample/common.sample.php $WROOT/protected/config/local/common.$                sudo cp -n $WROOT/protected/config/local.sample/console.sample.php $WROOT/protected/config/local/consol$
fi;
#TODO: If DB doesn't exist then create it - if ENV sample=demo, etc, then call oe-reset (--demo) --no-dependencies --no-migrate
#TODO: Deal with database server not being ready

# Start apache and mysql
service mysql start
apachectl -DFOREGROUND
