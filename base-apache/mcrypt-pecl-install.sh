#!/bin/bash -l

DEBIAN_FRONTEND=noninteractive

apt-get update \
&& apt-get -y install --no-install-recommends php${PHP_VERSION}-dev gcc make autoconf libc-dev pkg-config libmcrypt-dev php-pear \
&& pecl channel-update pecl.php.net \
&& pecl install mcrypt-1.0.2 \
&& [ -f /usr/lib/php/20170718/mcrypt.so ] && echo /usr/lib/php/20170718/mcrypt.so > /etc/php/${PHP_VERSION}/cli/conf.d/mcrypt.ini || : \
&& [ -f /usr/lib/php/20180731/mcrypt.so ] && echo extension=/usr/lib/php/20180731/mcrypt.so > /etc/php/${PHP_VERSION}/cli/conf.d/mcrypt.ini || : \
&& [ -f /usr/lib/php/20170718/mcrypt.so ] && echo /usr/lib/php/20170718/mcrypt.so > /etc/php/${PHP_VERSION}/apache2/conf.d/mcrypt.ini || : \
&& [ -f /usr/lib/php/20180731/mcrypt.so ] && echo extension=/usr/lib/php/20180731/mcrypt.so > /etc/php/${PHP_VERSION}/apache2/conf.d/mcrypt.ini || : \
&& apt-get remove -y php${PHP_VERSION}-dev \
&& apt-get autoremove -y \
&& apt-get clean -y \
&& rm -rf /var/lib/apt/lists/*

