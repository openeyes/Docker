#!/bin/bash

branch=master
defaultbranch=$BUILD_BRANCH
live=0
develop=0
force=0
customgitroot=0
gitroot=AppertaFoundation
cleanconfig=0
username=""
pass=""
httpuserstring=""
usessh=0
sshuserstring="git"
checkoutparams=""
genetics=0

[ "$LOCAL_DB" = "TRUE" ] && service mysql start || :
echo "setting mysql password to $MYSQL_ROOT_PASSWORD"
mysql -e "FLUSH PRIVILEGES; UPDATE mysql.user SET password = PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE user = 'root'; UPDATE mysql.user SET authentication_string = '' WHERE user = 'root'; UPDATE mysql.user SET plugin = '' WHERE user = 'root'; FLUSH PRIVILEGES;"

echo "

Installing openeyes $branch from https://gitgub.com/$gitroot
"


echo "
Downloading OpenEyes code base...
"

mkdir -p /etc/openeyes
cp -n /vagrant/install/etc/openeyes/* /etc/openeyes/


# Fix permissions
cd /var/www
echo "Setting file permissions..."
sudo gpasswd -a "$USER" www-data
sudo chown -R "$USER":www-data .

sudo chmod -R 774 .
sudo chmod -R g+s .

# add the sample DB
[ "$BUILD_SAMPLE" = "TRUE" ] && { checkoutparams="$checkoutparams --sample"; echo "Sample database wil be installed."; } || :

echo calling oe-checkout with $checkoutparams
/vagrant/install/runcheckout.sh $BUILD_BRANCH -f --no-migrate --no-summary --no-fix $checkoutparams


cd $WROOT/protected

git submodule init
git submodule update --init

mkdir -p $WROOT/cache
mkdir -p $WROOT/assets
mkdir -p $WROOT/protected/cache
mkdir -p $WROOT/protected/cache/events
mkdir -p $WROOT/protected/files
mkdir -p $WROOT/protected/runtime
mkdir -p $WROOT/protected/runtime/cache
chmod 777 $WROOT/cache
chmod 777 $WROOT/assets
chmod 777 $WROOT/protected/cache
chmod 777 $WROOT/protected/cache/events
chmod 777 $WROOT/protected/files
chmod 777 $WROOT/protected/runtime
chmod 777 $WROOT/protected/runtime/cache

chown -R "$USER":www-data /var/www/*

sed -i "s/envtype=AWS/envtype=DOCKER/" /etc/openeyes/env.conf
cp -f /vagrant/install/bashrc /root/.bashrc
usermod -a -G www-data $USER
usermod -a -G root $USER
# fix file access errors for user - for cache, etc (new files created by apache)
chmod g+w /etc/apache2/envvars
grep -q -e 'umask 001' /etc/apache2/envvars || sudo echo 'umask 001' >> /etc/apache2/envvars


echo "# env can be one of DEV or LIVE
# envtype can be one of LIVE, AWS or VAGRANT
env=$OE_MODE
envtype=DOCKER
" >/etc/openeyes/env.conf

[ ! -f $WROOT/protected/config/local/common.php ] && cp $WROOT/protected/config/local.sample $WROOT/protected/config/local || : 

resetswitches="--no-migrate --no-fix --banner '$BUILD_BRANCH'"

[ $genetics = 1 ] && resetswitches="$resetswitches --genetics-enable" || :
[ "$USE_DEMO_DATA" = "TRUE" ] && resetswitches="$resetswitches --demo" || :

oe-reset $resetswitches

# call oe-fix - this includes migrations
oe-fix

sed -i "s/'environment' => 'dev',/'environment' => '$OE_MODE',/" $WROOT/protected/config/local/common.php

echo Configuring Apache

sudo echo "
<VirtualHost *:80>
ServerName hostname
DocumentRoot /var/www/openeyes
<Directory /var/www/openeyes>
	Options FollowSymLinks
	AllowOverride All
	Order allow,deny
	Allow from all
</Directory>
ErrorLog /var/log/apache2/error.log
LogLevel warn
CustomLog /var/log/apache2/access.log combined
</VirtualHost>
" | sudo tee /etc/apache2/sites-available/000-default.conf >/dev/null

# Copy DICOM related files in place as required
cp -f /vagrant/install/dicom-file-watcher.conf /etc/init/
cp -f /vagrant/install/dicom /etc/cron.d/
cp -f /vagrant/install/run-dicom-service.sh /usr/local/bin
chmod +x /usr/local/bin/run-dicom-service.sh
id -u iolmaster &>/dev/null || sudo useradd iolmaster -s /bin/false -m
mkdir -p /home/iolmaster/test
mkdir -p /home/iolmaster/incoming
chown iolmaster:www-data /home/iolmaster/*
chmod 775 /home/iolmaster/*

echo ""
oe-which

echo --------------------------------------------------
echo OPENEYES SOFTWARE INSTALLED
echo Please check previous messages for any errors
echo --------------------------------------------------