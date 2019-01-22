## Builds a base image with OS application dependencies ready installed
## For use with OpenEyes.

ARG OS_VERSION=bionic
ARG PHP_VERSION="5.6"

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
    nano \
    unzip \
    xfonts-75dpi \
    xfonts-base \
    sudo \
    wget \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean -y \
  && rm -rf /var/www/html/* \
  && git config --global core.fileMode false

# Add additional PPAs depending on OS
ADD sources.${OS_VERSION}/ sources
ADD set-sources.sh set-sources.sh

RUN bash set-sources.sh

# Install furtherapps, plus npm, using additional PPAs
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libapache2-mod-php${PHP_VERSION} \
    nodejs \
    npm \
    php${PHP_VERSION} \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mcrypt \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-xsl \
    php${PHP_VERSION}-zip \
    ruby-compass \
  && npm install -g npm \
  && npm install -g grunt-cli \
  && a2enmod rewrite \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# Install wkhtmltopdf
RUN wget -O /wkhtml.deb https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb \
    && dpkg -i --force-depends /wkhtml.deb \
    && rm /wkhtml.deb

# SETUP apache config
# Enable display_errors and error logging for PHP, plus configure timezone
RUN mkdir /var/log/php 2>/dev/null || : \
  && chown www-data /var/log/php \
  && chown www-data /var/log/php \
  && sed -i "s/^display_errors = Off/display_errors = On/" /etc/php/${PHP_VERSION}/apache2/php.ini \
  && sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php/${PHP_VERSION}/apache2/php.ini \
  && sed -i "s|^;date.timezone =|date.timezone = ${TZ:-'Europe/London'}|" /etc/php/${PHP_VERSION}/apache2/php.ini \
  && sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php/${PHP_VERSION}/apache2/php.ini \
  && sed -i "s/^display_errors = Off/display_errors = On/" /etc/php/${PHP_VERSION}/cli/php.ini \
  && sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php/${PHP_VERSION}/cli/php.ini \
  && sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php/${PHP_VERSION}/cli/php.ini \
  && sed -i "s|^;date.timezone =|date.timezone = ${TZ:-'Europe/London'}|" /etc/php/${PHP_VERSION}/cli/php.ini \
  && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
  && a2enmod rewrite

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php \
  && php -r "unlink('composer-setup.php');" \
  && mv composer.phar /usr/local/bin/composer

EXPOSE 80 3306
