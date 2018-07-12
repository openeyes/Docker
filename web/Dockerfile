FROM php:5.6.36-apache-stretch

ENV TZ=Europe/London

RUN a2enmod rewrite && \
    docker-php-ext-install pdo_mysql && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 80
