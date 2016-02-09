#/bin/sh
set -e
set -x

cp /tmp/composer.json /var/www
cd /var/www
composer install
chown -R www-data:www-data /var/www/vendor /var/www/composer.json
