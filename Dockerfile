FROM php:8.0.3-apache
# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG DEBIAN_FRONTEND=noninteractive
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile" 

# Install dependencies
#ENV DEBIAN_FRONTEND
RUN apt-get update -y && \
      apt-get upgrade -y && \
      apt-get dist-upgrade -y && \
      apt-get -y autoremove && \
      apt-get clean

# Incredible : Renater, for some reason, blocks deb.debian.org; this has to be run on a different network
RUN apt-get install -y git \
      imagemagick \
      wget \
      unzip \
      apache2 \
      apache2-utils \
      dos2unix
RUN docker-php-ext-install exif mysqli

# Install omeka
WORKDIR /var/www
RUN git clone --recursive https://github.com/omeka/Omeka.git
RUN chown -R root.www-data Omeka && chmod 775 Omeka
WORKDIR /var/www/Omeka
RUN pwd
RUN rm db.ini.changeme
COPY db.ini ./db.ini
RUN dos2unix ./db.ini
RUN rm .htaccess.changeme
COPY .htaccess ./.htaccess
RUN rm application/config/config.ini.changeme
COPY config.ini application/config/config.ini
RUN dos2unix application/config/config.ini
RUN mv application/logs/errors.log.empty application/logs/errors.log
WORKDIR /var/www/Omeka/plugins
RUN wget https://github.com/omeka/plugin-OmekaApiImport/releases/download/v1.1.2/OmekaApiImport.zip
RUN unzip OmekaApiImport.zip
RUN rm OmekaApiImport.zip
WORKDIR /var/www/Omeka
RUN pwd
RUN find . -type d | xargs chmod 775
RUN find . -type f | xargs chmod 664
RUN find files -type d | xargs chmod 777
RUN find files -type f | xargs chmod 666

# Configure apache
COPY omeka.conf /etc/apache2/sites-available/omeka.conf
RUN dos2unix /etc/apache2/sites-available/omeka.conf
RUN a2enmod rewrite
RUN a2ensite omeka
RUN a2dissite 000-default
ENV APPLICATION_ENV development
ENV HTTPS false

# Configure php
ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_MAX_FILESIZE 100M
ENV PHP_POST_MAX_SIZE 100M

# Configure mysql
ENV OMEKA_DB_HOST localhost
ENV OMEKA_DB_USER omeka
ENV OMEKA_DB_PASSWORD omeka
ENV OMEKA_DB_NAME omeka
ENV OMEKA_DB_PREFIX _omeka
ENV OMEKA_DB_CHARSET utf8

# Add init script
COPY run.sh /run.sh
RUN dos2unix "/run.sh"
RUN chmod 755 /*.sh

# Expose 443 for https
RUN echo "enabling https..."
EXPOSE 443

# Run the server
RUN echo "run.sh..."
CMD ["/run.sh"]
