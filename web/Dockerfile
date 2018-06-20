FROM ubuntu:trusty

RUN apt-get update -y && apt-get upgrade -y && apt-get autoremove -y && \ 
    apt-get install -y git-core libapache2-mod-php5 php5-cli php5-mysql php5-ldap php5-curl php5-xsl php5-gd imagemagick php5-imagick libjpeg62 mariadb-server mariadb-client debconf-utils unzip xfonts-75dpi default-jre libgamin0 gamin xfonts-base ruby libreoffice-core libreoffice-common libreoffice-writer php5-mcrypt curl && \ 
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

RUN apt-get install -y nodejs && npm install -g npm && npm install -g grunt-cli


