#!/bin/bash
rm /var/www/html/application.properties
for var in $(echo ${properties} ${backend_properties} | tr ',' ' ')
do
  variable=$${var%:*}
  value=$${var##*:}
  echo $$variable = $$value >> /var/www/html/application.properties
done
