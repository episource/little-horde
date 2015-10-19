FROM combro2k/horde-webmail:latest

MAINTAINER Philipp Serr

# Enable sqlite
RUN apt-get update
RUN apt-get install -y php5-sqlite
RUN php5enmod sqlite3

# Prepare SSL/HTTPS
EXPOSE 443
ADD horde-ssl.conf /etc/apache2/sites-available/horde-ssl.conf
ADD setup-https /usr/local/bin/setup-https
RUN chmod +x /usr/local/bin/setup-https
RUN a2enmod ssl
RUN a2dissite default-ssl
RUN a2ensite horde-ssl


# Prepare data volumes
RUN chown www-data:www-data /etc/horde
RUN mkdir -p /etc/apache2/ssl
VOLUME /etc/apache2/ssl
RUN mkdir -p /srv/sqlite
RUN chown www-data:www-data /srv/sqlite
VOLUME /srv/sqlite 


## Horde default configuration using sqlite backend and Active Directory
RUN rm /etc/.horde/horde/conf.php.dist
ADD conf.php.dist /etc/.horde/horde/conf.php.dist
RUN chown -R www-data:www-data /etc/.horde


# Update horde init script
RUN rm /etc/my_init.d/horde-init.sh
ADD horde-init.sh /etc/my_init.d/horde-init.sh
RUN chmod +x /etc/my_init.d/horde-init.sh


# Reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#CMD ["/sbin/my_init"]
