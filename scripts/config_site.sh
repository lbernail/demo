#/bin/sh
set -e
set -x

rm -rf /var/www/html
mv /tmp/html /var/www/html

cd /var/www/html
composer install

chown -R www-data:www-data /var/www/html
