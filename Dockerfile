FROM debian:stretch-slim
MAINTAINER IP2Location <support@ip2location.com>

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq install wget unzip sudo gnupg
RUN wget --no-check-certificate https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' > /etc/apt/sources.list.d/pgdg.list
RUN apt-key add ACCC4CF8.asc
RUN apt-get update && apt-get -yq install postgresql-10 postgresql-server-dev-10 build-essential libxml2-dev libgdal-dev libproj-dev libjson-c-dev xsltproc docbook-xsl docbook-mathml gcc
RUN wget https://download.osgeo.org/postgis/source/postgis-2.5.2.tar.gz
RUN tar xvzf postgis-2.5.2.tar.gz
RUN cd postgis-2.5.2 && ./configure && make && make install

# Update PostgreSQL settings
RUN echo "" >> /etc/postgresql/10/main/pg_hba.conf
RUN echo "host	all		all		0.0.0.0/0		md5" >> /etc/postgresql/10/main/pg_hba.conf
RUN sed -i -e "s/^#listen_addresses.*=.*/listen_addresses = '*'/" /etc/postgresql/10/main/postgresql.conf

# Add MySQL scripts
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Exposed ENV
ENV TOKEN FALSE
ENV CODE FALSE
ENV POSTGRESQL_PASSWORD FALSE

VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
EXPOSE 5432
CMD ["/run.sh"]