FROM debian:buster-slim

LABEL maintainer="support@ip2location.com"

# Install packages
RUN apt-get update && apt-get install -y wget unzip sudo gnupg
RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list
RUN apt-key add ACCC4CF8.asc
RUN apt-get install -y postgresql
# Update PostgreSQL settings
RUN echo "" >> /etc/postgresql/11/main/pg_hba.conf
RUN echo "host	all		all		0.0.0.0/0		md5" >> /etc/postgresql/11/main/pg_hba.conf
RUN sed -i -e "s/^#listen_addresses.*=.*/listen_addresses = '*'/" /etc/postgresql/11/main/postgresql.conf

# Add MySQL scripts
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Exposed ENV
ENV TOKEN FALSE
ENV CODE FALSE
ENV IP_TYPE FALSE
ENV POSTGRESQL_PASSWORD FALSE

VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
EXPOSE 5432
CMD ["/run.sh"]