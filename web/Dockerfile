FROM php:5.6-apache

COPY etc-openeyes /etc/openeyes
COPY db.conf /etc/openeyes/db.conf
COPY var-www-openeyes /var/www/openeyes
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

RUN chown -R root:www-data /var/www/openeyes && \ 
    chown -R root:root /etc/openeyes/ && \ 
    sed -i '1 i\ServerName openeyes' /etc/apache2/apache2.conf && \ 
    service apache2 restart

