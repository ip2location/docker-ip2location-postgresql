docker-ip2location-postgresql
=============================

This is a pre-configured, ready-to-run PostgreSQL with IP2Location Geolocation database setup scripts. It simplifies the development team to install and set up the geolocation database in PostgreSQL. The setup script supports the [commercial database packages](https://www.ip2location.com) and [free LITE package](https://lite.ip2location.com). Please register for a download account before running this image.

### Usage

1. Run this image as daemon with your download token and download code registered from [IP2Location](https://www.ip2location.com).

       docker run --name ip2location -d -e POSTGRESQL_PASSWORD=YOUR_POSTGRESQL_PASSWORD -e TOKEN=YOUR_TOKEN -e CODE=DOWNLOAD_CODE ip2location/postgresql

    **ENV VARIABLE**

   TOKEN - Download token form IP2Location account.

   CODE - Database code. Codes available as below:

    **Free Database**

     * DB1-LITE, DB3-LITE, DB5-LITE, DB9-LITE, DB11-LITE

   **Commercial Database**

   * DB1, DB2, DB3, DB4, DB5, DB6, DB7, DB8, DB9, DB10, DB11, DB12, DB13, DB14, DB15, DB16, DB17, DB18, DB19, DB20, DB21, DB22, DB23, DB24, DB25

   IP_TYPE - (Optional) Download IPv4 or IPv6 database. Script will download IPv4 database by default.

   * IPV4 - Download IPv4 database only.
   * IPV6 - Download IPv6 database only.

  POSTGRESQL_PASSWORD - (Optional) Password for PostgreSQL admin. A random password will be generated by default.

2. The installation may take minutes to hour depending on your internet speed and hardware. You may check the installation status by viewing the container logs. Run the below command to check the container log:

        docker logs YOUR_CONTAINER_ID

    You should see the line of `=> Setup completed` if you have successfully complete the installation.

### Connect to it from an application

    docker run --link ip2location:ip2location-db -t -i application_using_the_ip2location_data

### Make the query

    psql -h ip2location-db --username=postgres -d ip2location_database

Enter YOUR_POSTGRESQL_PASSWORD password when prompted.

Start lookup by following query:

    SELECT * FROM ip2location_database WHERE ip2int('8.8.8.8') BETWEEN ip_from AND ip_to LIMIT 1;

Notes: For IPv6 lookup, please convert the IPv6 into BigInt programmatically. There is no build-in function available with PostgreSQL.

### Sample Code Reference

[https://www.ip2location.com/tutorials](https://www.ip2location.com/tutorials)
