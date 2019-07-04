#!/bin/bash -l

[ ! -f /etc/php/$PHP_VERSION/apache2/conf.d/99-openeyes.ini ] && touch /etc/php/$PHP_VERSION/apache2/conf.d/99-openeyes.ini

# Process any custom environment variables for PHP ini
for env in $(printenv | grep '^PHPI_'); do
    name="$(cut -c6- <<< ${env%%=*} | tr 'A-Z' 'a-z')"
    val="${env##*=}"
    [[ "$val" =~ ^\"([0-9]+|false|true)\"$ ]] && val="$(sed 's|"||g' <<< $val)"

    if grep -q "^$name = $val" /etc/php/${PHP_VERSION}/apache2/conf.d/99-openeyes.ini; then
        # If name and value already exist - do nothing
        :
    elif grep -q "$name =" /etc/php/${PHP_VERSION}/apache2/conf.d/99-openeyes.ini; then
        # if name exists, but has a different value - overwrite with the new value
        echo "updating $name to $val"
        sed -i "s/^$name .*/$name = $val/" /etc/php/${PHP_VERSION}/apache2/conf.d/99-openeyes.ini
    else
        # if name doesn't exist, add it to the file 
        echo "adding $name = $val"
        echo -e "\n$name = $val" >> /etc/php/${PHP_VERSION}/apache2/conf.d/99-openeyes.ini
    fi
done