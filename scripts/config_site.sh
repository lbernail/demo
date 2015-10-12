#/bin/sh
set -e
set -x

rm -rf /var/www/html
mv /tmp/html /var/www/html

chown -R www-data:www-data /var/www/html
