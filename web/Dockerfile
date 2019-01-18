FROM appertaopeneyes/base-apache

ARG BUILD_BRANCH=develop
ARG BUILD_GITROOT
ARG BUILD_SAMPLE=TRUE
ARG BUILD_LOCAL_DB=FALSE
	# By default we expect an external database container to be used
	# Set this arg to TRUE to install mariadb inside the container
ARG BUILD_EXTRA_PACKAGES=""
  # Add additional apt packages
ARG APACHE_VERSION=5.6

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/London
ENV OE_MODE=DEV
ENV LOCAL_DB=$BUILD_LOCAL_DB
ENV SSH_PRIVATE_KEY=""

## Database connection credentials:
## It is STRONGLY recommended to change the password for production environments
## It is STRONGLY recommended to use docker secrets for DATABASE_PASS, rather than env variables
## defaults are localhost; openeyes; 3306; openeyes; openeyes
ENV DATABASE_HOST="localhost"
ENV DATABASE_NAME="openeyes"
ENV DATABASE_PORT="3306"
ENV DATABASE_USER="openeyes"
ENV DATABASE_PASS="openeyes"
ENV USE_DEMO_DATA=TRUE

## MySQL/MariaDB root login credentials (used for install / reset scripts)
## It is strongly recommended that you use docker secrets or similar methods
## To set these, as opposed to using environment variables!
## It is also STRONGLY recommended to change your root password in production
## environments
ENV MYSQL_ROOT_PASSWORD=""
ENV MYSQL_SUPER_USER="root"

WORKDIR /

# set up folders
RUN mkdir /openeyes

# ARG CACHEBUSTER=$RANDOM
	# Use this to prevent build cache using an old version of source files

RUN ssh -oStrictHostKeyChecking=no git@github.com -T &> /dev/null


RUN [ "$BUILD_LOCAL_DB" = "TRUE" ] && { apt-get update && apt-get install -y mariadb-server mariadb-client \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/* ; }

RUN chgrp -R www-data /openeyes

# Add the init script
COPY init.sh init.sh
RUN chmod a+rx init.sh

# SETUP apache config
# Enable display_errors and error logging for PHP, plus configure timezone
  RUN mkdir /var/log/php 2>/dev/null || : \
  && chown www-data /var/log/php \
  && chown www-data /var/log/php \
  && sed -i "s/^display_errors = Off/display_errors = On/" /etc/php/${APACHE_VERSION}/apache2/php.ini \
  && sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php/${APACHE_VERSION}/apache2/php.ini \
  && sed -i "s|^;date.timezone =|date.timezone = ${TZ:-'Europe/London'}|" /etc/php/${APACHE_VERSION}/apache2/php.ini \
  && sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php/${APACHE_VERSION}/apache2/php.ini \
  && sed -i "s/^display_errors = Off/display_errors = On/" /etc/php/${APACHE_VERSION}/cli/php.ini \
  && sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php/${APACHE_VERSION}/cli/php.ini \
  && sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php/${APACHE_VERSION}/cli/php.ini \
  && sed -i "s|^;date.timezone =|date.timezone = ${TZ:-'Europe/London'}|" /etc/php/${APACHE_VERSION}/cli/php.ini \
  && sed -i "s|DocumentRoot /var/www/html|DocumentRoot /openeyes|" /etc/apache2/sites-available/000-default.conf \
	&& sed -i "s|<Directory /var/www/html>|<Directory /openeyes>|" /etc/apache2/sites-available/000-default.conf \
  && a2enmod rewrite

EXPOSE 80 3306

VOLUME /openeyes
# /cache /config /logs /protectedfiles

# ENTRYPOINT
CMD /init.sh
