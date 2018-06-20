FROM ubuntu:trusty

RUN apt-get update -y && apt-get upgrade -y && apt-get autoremove -y && \ 
    apt-get install -y git-core libapache2-mod-php5 php5-cli php5-mysql php5-ldap php5-curl php5-xsl php5-gd imagemagick php5-imagick libjpeg62 mariadb-server mariadb-client debconf-utils unzip xfonts-75dpi default-jre libgamin0 gamin xfonts-base ruby libreoffice-core libreoffice-common libreoffice-writer php5-mcrypt curl && \ 
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

RUN apt-get install -y nodejs && npm install -g npm && npm install -g grunt-cli

RUN mkdir /var/log/php 2>/dev/null &&  chown www-data /var/log/php && \ 
    sed -i "s/^display_errors = Off/display_errors = On/" /etc/php5/apache2/php.ini && \ 
    sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php5/apache2/php.ini && \ 
    sed -i "s/^;date.timezone =/date.timezone = \"Europe\/London\"/" /etc/php5/apache2/php.ini && \ 
    sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php5/apache2/php.ini && \ 
    sed -i "s/^display_errors = Off/display_errors = On/" /etc/php5/cli/php.ini && \ 
    sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php5/cli/php.ini && \ 
    sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php5/cli/php.ini && \ 
    sed -i "s/^;date.timezone =/date.timezone = \"Europe\/London\"/" /etc/php5/cli/php.ini



