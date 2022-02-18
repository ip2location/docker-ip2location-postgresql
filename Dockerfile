FROM debian:bullseye-slim

LABEL maintainer="support@ip2location.com"

# Install packages
RUN apt-get update && apt-get install -y wget unzip sudo gnupg postgresql

# Add setup scripts
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