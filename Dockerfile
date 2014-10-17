FROM debian:wheezy
MAINTAINER IP2Location <support@ip2location.com>

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq install wget unzip sudo
RUN wget --no-check-certificate https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main' > /etc/apt/sources.list.d/pgdg.list
RUN apt-key add ACCC4CF8.asc
RUN apt-get update && apt-get -yq install postgresql-9.3

# Update PostgreSQL settings
RUN echo "host	all	all	0.0.0.0/0	md5" >> /etc/postgresql/9.3/main/pg_hba.conf
RUN sed -i -e "s/^#listen_addresses.*=.*/listen_addresses = '*'/" /etc/postgresql/9.3/main/postgresql.conf

# Add MySQL scripts
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Exposed ENV
ENV USERNAME FALSE
ENV PASSWORD FALSE
ENV CODE FALSE
ENV POSTGRESQL_PASSWORD FALSE

VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
EXPOSE 5432
CMD ["/run.sh"]