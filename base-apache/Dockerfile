## Builds a base image with OS application dependencies ready installed
## For use with OpenEyes

ARG OS_VERSION=bionic

FROM ubuntu:$OS_VERSION

ARG OS_VERSION
ARG DEBIAN_FRONTEND=noninteractive
ARG TIMEZONE="Europe/London"

ENV TZ=$TIMEZONE

WORKDIR /root/

# Set timezone, add common packes, apt clean at the end to minimise layer size
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && apt-get update && apt-get install -y \
   apache2 \
   curl \
   debconf-utils \
   gamin \
   git-core \
   gnupg \
   libgamin0 \
   libjpeg62 \
   libreoffice-common \
   libreoffice-core \
   libreoffice-writer \
   unzip \
   xfonts-75dpi \
   xfonts-base \
   sudo \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/www/html/* 

# Add additional PPAs depending on OS
ADD sources.${OS_VERSION}/ sources
ADD set-sources.sh set-sources.sh

RUN bash set-sources.sh 

# Install furtherapps, plus npm, using additional PPAs
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libapache2-mod-php5.6 \
    nodejs \
    npm \
    php5.6 \
    php5.6-cli \
    php5.6-curl \
    php5.6-gd \
    php5.6-imagick \
    php5.6-ldap \
    php5.6-mbstring \
    php5.6-mcrypt \
    php5.6-mysql \
    php5.6-xsl \
    php5.6-zip \
    ruby-compass \
 && npm install -g npm \
 && npm install -g grunt-cli \
 && sudo wget -O wkhtml.deb https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb \
 && dpkg -i --force-depends wkhtml.deb \
 && rm wkhtml.deb \
 && a2enmod rewrite \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php composer-setup.php \
 && php -r "unlink('composer-setup.php');" \
 && mv composer.phar /usr/local/bin/composer

