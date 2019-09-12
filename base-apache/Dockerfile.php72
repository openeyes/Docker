## Builds a base image with OS application dependencies ready installed
## For use with OpenEyes.

ARG OS_VERSION=bionic
ARG BUILD_PHP_VERSION="7.2"

FROM ubuntu:$OS_VERSION

ARG OS_VERSION
ARG BUILD_PHP_VERSION
ARG DEBIAN_FRONTEND=noninteractive
ARG TIMEZONE="Europe/London"

ENV TZ=$TIMEZONE

ENV PHP_VERSION=$BUILD_PHP_VERSION

# Set timezone, add common packages, apt clean at the end to minimise layer size
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    bc \
    curl \
    cron \
    debconf-utils \
    gamin \
    ghostscript \
    git-core \
    gnupg \
    jq \
    libgamin0 \
    libjpeg62 \
    libreoffice-common \
    libreoffice-core \
    libreoffice-writer \
    mariadb-client \
    nano \
    ssh \
    unzip \
    xfonts-75dpi \
    xfonts-base \
    sudo \
    wget \
    zip \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean -y \
  && rm -rf /var/www/html/* \
  && git config --global core.fileMode false

# Add additional PPAs depending on OS
ADD sources.${OS_VERSION}/ sources
ADD set-sources.sh set-sources.sh

RUN bash set-sources.sh \
    && echo ". /etc/profile" >> /root/.bashrc \
    && echo ". /env.sh 2>/dev/null " >> /root/.bashrc

# Install furtherapps, plus npm, using additional PPAs
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-xsl \
    php${PHP_VERSION}-zip \
    ruby-compass \
  && [ $(echo "${PHP_VERSION} < 7.2" | bc -l) = 1 ] && apt-get install -y --no-install-recommends php${PHP_VERSION}-mcrypt || : \
  && npm install -g npm \
  && npm install -g grunt-cli \
  && a2enmod rewrite \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# Install wkhtmltopdf
RUN wget -O /wkhtml.deb https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.${OS_VERSION}_amd64.deb \
    && dpkg -i --force-depends /wkhtml.deb \
    && rm /wkhtml.deb

# SETUP apache config
# Enable add custom PHP and apache settings (including timezone), plus configure SSH
COPY 99-openeyes.ini /etc/php/${PHP_VERSION}/apache2/conf.d/99-openeyes.ini
COPY set_php_vars.sh /set_php_vars.sh
RUN chmod 774 /set_php_vars.sh \ 
  && bash /set_php_vars.sh \
  && echo "date.timezone = ${TZ:-'Europe/London'}" > /etc/php/${PHP_VERSION}/apache2/conf.d/99-timezone.ini \
  && ln -sf /etc/php/${PHP_VERSION}/apache2/conf.d/99-openeyes.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-openeyes.ini \
  && ln -sf /etc/php/${PHP_VERSION}/apache2/conf.d/99-timezone.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-timezone.ini \
  && mkdir -p /var/log/php 2>/dev/null || : \
  && chown www-data /var/log/php \
  && chown www-data /var/log/php \
  && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
  && a2enmod rewrite \
  && echo "AuthorizedKeysFile  /run/.ssh/authorized_keys /.authorized_keys .ssh/authorized_keys %h/.ssh/authorized_keys" >> /etc/ssh/sshd_config
  
# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php \
  && php -r "unlink('composer-setup.php');" \
  && mv composer.phar /usr/local/bin/composer

# As mcrypt was retired in php7.2, we have to complie it from pecl
# which SIGNIFICANTLY increases image size. 
# this is temporary until mcrypt is removed from OpenEyes (it is only used by OphCoCvi module for signature encryption)
COPY mcrypt-pecl-install.sh mcrypt-pecl-install.sh
# RUN [ $(echo "${PHP_VERSION} > 7.1" | bc -l) = 1 ] && bash mcrypt-pecl-install.sh || :

## Note that mcrypt install for 7.2+ is currently commented out, awaiting outcome of https://github.com/openeyes/OpenEyes/issues/3421
## run /mcrypt-pecl-install.sh manually if mcrypt is needed for testing (or uncomment the previous RUN line in the dockerfile and rebuild)

EXPOSE 80 3306 22
