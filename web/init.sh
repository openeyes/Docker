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

#TODO: bind mount volumes to OE folders

# Ensure .htaccess is set
if [ ! -f "/var/www/html/.htaccess" ]; then
    echo Renaming .htaccess file
    mv /var/www/html/.htaccess.sample /var/www/html/.htaccess
    sudo chown www-data:www-data /var/www/html/.htaccess
fi

# ensure index is set
if [ ! -f "/var/www/html/index.php" ]; then
    echo Renaming index.php file
    mv /var/www/html/index.example.php /var/www/html/index.php
    sudo chown www-data:www-data /var/www/html/index.php
fi

#TODO: If DB doesn't exist then create it - if ENV sample=demo, etc, then call oe-reset (--demo) --no-dependencies --no-migrate
#TODO: Deal with database server not being ready

# call oe-migrate
bash /var/www/html/protected/scripts/oe-migrate.sh

# Start apache
apachectl -DFOREGROUND
