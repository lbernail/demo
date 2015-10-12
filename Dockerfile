from debian:jessie

MAINTAINER Laurent Bernaille <laurent.bernaille@d2-si.eu>

COPY scripts/install_packages.sh /tmp/
RUN /tmp/install_packages.sh

COPY site/composer.json /tmp/composer.json
COPY scripts/install_php_archives.sh /tmp/install_php_archives.sh
RUN /tmp/install_php_archives.sh

COPY site /tmp/html
COPY scripts/config_site.sh /tmp/
RUN /tmp/config_site.sh

EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
