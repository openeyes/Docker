FROM php:5.6.36-apache-stretch

COPY etc-openeyes /etc/openeyes
COPY var-www-openeyes /var/www/html
COPY php.ini /usr/local/etc/php/

ENV TZ=Europe/London

RUN chown -R root:www-data /var/www/html && \
    chown -R root:root /etc/openeyes/ && \
    chmod g+w /var/www/html/protected/runtime && \
    chmod g+w /var/www/html/assets && \
    a2enmod rewrite && \
    docker-php-ext-install pdo_mysql && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

