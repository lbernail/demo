#/bin/sh
set -e
set -x

BUILDDEPS=curl

# install required packages
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y apache2 php5 libapache2-mod-php5 php5-curl php5-mysql curl

# isntall composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

## Clear unneeded binaries
apt-get remove -y $BUILDDEPS
apt-get autoclean
apt-get --purge -y autoremove
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
