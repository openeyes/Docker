FROM php:5.6.36-apache-stretch

COPY etc-openeyes /etc/openeyes
COPY db.conf /etc/openeyes/db.conf
COPY var-www-openeyes /var/www/html

RUN chown -R root:www-data /var/www/html && \
    chown -R root:root /etc/openeyes/ && \
    chmod g+w /var/www/html/protected/runtime && \
    a2enmod rewrite

