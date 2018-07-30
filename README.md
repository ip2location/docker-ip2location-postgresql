docker-ip2location-postgresql
=============================

This is a pre-configured, ready-to-run PostgreSQL with IP2Location Geolocation database setup scripts. It simplifies the development team to install and set up the geolocation database in PostgreSQL. The setup script supports the [commercial database packages](https://www.ip2location.com) and [free LITE package](https://lite.ip2location.com). Please register for a download account before running this image.

### Usage

1. Run this image as daemon with your download token and download code registered from [IP2Location](https://www.ip2location.com).

       docker run --name ip2location -d -e POSTGRESQL_PASSWORD=YOUR_POSTGRESQL_PASSWORD -e TOKEN=YOUR_TOKEN -e CODE=DOWNLOAD_CODE ip2location/postgresql

    **ENV VARIABLE**

    POSTGRESQL_PASSWORD – Enter a password for user admin.

    TOKEN – Download token form IP2Location account.

    CODE – The CSV file download code. You may get the download code from your account panel.

2. The installation may take minutes to hour depending on your internet speed and hardware. You may check the installation status by viewing the container logs. Run the below command to check the container log:

        docker logs YOUR_CONTAINER_ID

    You should see the line of `=> Setup completed` if you have successfully complete the installation.

### Connect to it from an application

    docker run --link ip2location:ip2location-db -t -i application_using_the_ip2location_data

### Make the query

    psql -h ip2location-db --username=postgres -d ip2location_database

Enter YOUR_POSTGRESQL_PASSWORD password when prompted.

Create a `inet_to_bigint` function for easier lookup.

    CREATE OR REPLACE FUNCTION inet_to_bigint(inet) RETURNS bigint AS $$ SELECT $1 - inet '0.0.0.0' $$ LANGUAGE SQL strict immutable;GRANT execute ON FUNCTION inet_to_bigint(inet) TO public;

Start lookup by following query:

    SELECT * FROM ip2location_database WHERE inet_to_bigint('8.8.8.8') <= ip_to LIMIT 1;


### Sample Code Reference

[https://www.ip2location.com/tutorials](https://www.ip2location.com/tutorials)
