FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive \ 
    TZ=Europe/London

RUN apt-get update \
 && apt-get install -y software-properties-common \
 && add-apt-repository ppa:ondrej/php \
 && apt-get update \
 && apt-get install -y sudo git-core curl php5.6 imagemagick libjpeg62 debconf-utils unzip xfonts-75dpi libgamin0 gamin xfonts-base ruby ant libreoffice-core libreoffice-common libreoffice-writer libapache2-mod-php5.6 php5.6-cli php5.6-mysql php5.6-ldap php5.6-curl php5.6-xsl php5.6-gd php-imagick php5.6-mcrypt php5.6-imagick

# install node.js, npm and grunt
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -  \
 && sudo apt-get install -y nodejs \
 && npm install -g npm \
# install grunt
 && npm install -g grunt-cli \
 && a2enmod rewrite \
 && rm -rf /var/lib/apt/lists/* \ 
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
 
EXPOSE 80

ENTRYPOINT apachectl -DFOREGROUND
