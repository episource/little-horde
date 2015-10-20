FROM ubuntu:15.10

MAINTAINER Philipp Serr

ENV HOME /root


# Add Tini
ENV TINI_VERSION v0.7.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]


# Install horde + webserver + sqlite
RUN apt-get update && apt-get install -y \
  apache2 php-horde php-horde-activesync php-horde-imp php-horde-groupware \
  php-horde-ingo php-horde-lz4 php-horde-syncml php5-imagick php5-dev php5-memcache \
  php5-memcached php-net-dns2 php-net-sieve php5-sqlite
  
# Enable necessary php modules
RUN pecl install lzf \
  && echo extension=lzf.so > /etc/php5/mods-available/lzf.ini && php5enmod lzf \
  && php5enmod sqlite3


EXPOSE 80 443


# Reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Prepare Webserver
RUN mkdir -p /etc/apache2/scripts
COPY proxy_client_ip.php /etc/apache2/scripts/proxy_client_ip.php

# Prepare HTTP
COPY horde.conf /etc/apache2/sites-available/horde.conf
RUN a2ensite horde && a2dissite 000-default && a2disconf php-horde

# Prepare SSL/HTTPS
COPY horde-ssl.conf /etc/apache2/sites-available/horde-ssl.conf
COPY setup-https /usr/local/bin/setup-https
RUN chmod +x /usr/local/bin/setup-https
RUN a2enmod ssl && a2dissite default-ssl && a2ensite horde-ssl


## Horde default configuration using sqlite backend and Active Directory
RUN mv /etc/horde /etc/.horde
RUN rm /etc/.horde/horde/conf.php.dist
COPY conf.php.dist /etc/.horde/horde/conf.php.dist
RUN chown -R www-data:www-data /etc/.horde


# Prepare data volumes
VOLUME /etc/horde
RUN chown www-data:www-data /etc/horde
RUN mkdir -p /etc/apache2/ssl
VOLUME /etc/apache2/ssl
RUN mkdir -p /srv/sqlite
RUN chown www-data:www-data /srv/sqlite
VOLUME /srv/sqlite 


# Horde init script
COPY horde-init.sh /sbin/horde-init.sh
RUN chmod +x /sbin/horde-init.sh


CMD ["/sbin/horde-init.sh"]
