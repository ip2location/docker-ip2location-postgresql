#!/bin/bash
if [ "$USERNAME" != "FALSE" ] && [ "$PASSWORD" != "FALSE" ] && [ "$CODE" != "FALSE" ] && [ ! -f /setup_done ]; then
	echo "=> Create directory /_tmp"
	mkdir /_tmp

	if [ ! -d /_tmp ]; then
		echo "=> Unable to create directory /_tmp"
		exit 1
	fi

	cd /_tmp

	echo "=> Download ${CODE} package"
	wget -O database.zip -q --user-agent="Docker-IP2Location/PostgreSQL" http://www.ip2location.com/download?login=${USERNAME}\&password=${PASSWORD}\&productcode=${CODE} 2>&1

	if [ ! -f database.zip ]; then
		echo "=> Download failed"
		exit 1
	fi

	if [ ! -z "$(grep 'NO PERMISSION' database.zip)" ]; then
		 echo "=> Permission denied"
		exit 1
	fi

	if [ ! -z "$(grep '5 times' database.zip)" ]; then
		 echo "=> Download quota exceed"
		exit 1
	fi

	if [ $(wc -c < database.zip) -lt 102400 ]; then
		echo "=> Download failed"
		exit 1	
	fi

	echo "=> Decompress downloaded package"
	
	unzip -q -o database.zip

	if [ "$CODE" == "DB1CSV" ]; then
		CSV="$(find . -name 'IPCountry.csv')"

	elif [ "$CODE" == "DB2CSV" ]; then
		CSV="$(find . -name 'IPISP.csv')"

	elif [ ! -z "$(echo $CODE | grep 'LITE')" ]; then
		CSV="$(find . -name 'IP2LOCATION-LITE-DB*.CSV')"

	elif [ ! -z "$(echo $CODE | grep 'LITECSVIPV6')" ]; then
		CSV="$(find . -name 'IP2LOCATION-LITE-DB*.IPV6.CSV')"

	elif [ ! -z "$(echo $CODE | grep 'CSVIPV6')" ]; then
		CSV="$(find . -name 'IPV6-COUNTRY*.CSV')"

	else
		CSV="$(find . -name 'IP-COUNTRY*.CSV')"

	fi

	if [ -z "$CSV" ]; then
		echo "=> Downloaded package is corrupted"
		exit 1
	fi

	echo "=> Starting PostgreSQL server..."
	service postgresql start >/dev/null 2>&1

	echo "=> [PostgreSQL] Create database \"ip2location_database\""

	RESPONSE="$(sudo -u postgres createdb ip2location_database 2>&1)"

	if [ ! -z "$(echo $RESPONSE | grep 'FATAL')" ]; then
		echo "=> [PostgreSQL] Unable to create database \"ip2location_database\""
		exit 1
	fi

	echo "=> [PostgreSQL] Create table \"ip2location_database_tmp\""

	case "$CODE" in
		DB1CSV|DB1LITECSV|DB1CSVIPV6|DB1LITECSVIPV6 )
			FIELDS=''
		;;
		DB2CSV|DB2CSVIPV6 )
			FIELDS=',isp varchar(255) NOT NULL'
		;;

		DB3CSV|DB3LITECSV|DB3CSVIPV6|DB3LITECSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL'
		;;

		DB4CSV|DB4CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL'
		;;

		DB5CSV|DB5LITECSV|DB5CSVIPV6|DB5LITECSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL'
		;;

		DB6CSV|DB6CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL'
		;;

		DB7CSV|DB7CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
		;;

		DB8CSV|DB8CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
		;;

		DB9CSV|DB9LITECSV|DB9CSVIPV6|DB9LITECSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL'
		;;

		DB10CSV|DB10CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
		;;

		DB11CSV|DB11LITECSV|DB11CSVIPV6|DB11LITECSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL'
		;;

		DB12CSV|DB12CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
		;;

		DB13CSV|DB13CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,time_zone varchar(8) NULL DEFAULT NULL,net_speed varchar(8) NOT NULL'
		;;

		DB14CSV|DB14CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL'
		;;

		DB15CSV|DB15CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL'
		;;

		DB16CSV|DB16CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL'
		;;

		DB17CSV|DB17CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,time_zone varchar(8) NULL DEFAULT NULL,net_speed varchar(8) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL'
		;;

		DB18CSV|DB18CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL'
		;;

		DB19CSV|DB19CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL'
		;;

		DB20CSV|DB20CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL'
		;;

		DB21CSV|DB21CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,elevation integer NOT NULL'
		;;

		DB22CSV|DB22CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,elevation integer NOT NULL'
		;;

		DB23CSV|DB23CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,usage_type varchar(11) NOT NULL'
		;;

		DB24CSV|DB24CSVIPV6 )
			FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,elevation integer NOT NULL,usage_type varchar(11) NOT NULL'
		;;
	esac

	if [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
		RESPONSE="$(sudo -u postgres psql -c 'CREATE TABLE ip2location_database_tmp (ip_from decimal(39,0) NOT NULL,ip_to decimal(39,0) NOT NULL,country_code CHARACTER(2) NOT NULL,country_name varchar(64) NOT NULL'"$FIELDS"');' ip2location_database 2>&1)"
	else
		RESPONSE="$(sudo -u postgres psql -c 'CREATE TABLE ip2location_database_tmp (ip_from bigint NOT NULL,ip_to bigint NOT NULL,country_code CHARACTER(2) NOT NULL,country_name varchar(64) NOT NULL'"$FIELDS"');' ip2location_database 2>&1)"
	fi

	if [ ! -z "$(echo $RESPONSE | grep 'ERROR')" ]; then
		echo "=> [PostgreSQL] Unable to create table \"ip2location_database_tmp\""
		exit 1
	fi

	sudo -u postgres psql -c 'CREATE INDEX idx_ip_to ON ip2location_database_tmp USING btree (ip_to) WITH (FILLFACTOR=100);' ip2location_database > /dev/null

	echo "=> [PostgreSQL] Load CSV data into \"ip2location_database_tmp\""

	RESPONSE="$(sudo -u postgres psql -c 'COPY ip2location_database_tmp FROM '\'''/_tmp/$CSV''\'' WITH CSV QUOTE AS '\''"'\'';' ip2location_database 2>&1)"

	if [ ! -z "$(echo $RESPONSE | grep 'ERROR')" ]; then
		echo "=> [PostgreSQL] Unable to load CSV data into \"ip2location_database_tmp\""
		exit 1
	fi

	echo "=> [PostgreSQL] Drop table \"ip2location_database\""

	RESPONSE="$(sudo -u postgres psql -c 'DROP TABLE IF EXISTS ip2location_database;' ip2location_database 2>&1)"

	if [ ! -z "$(echo $RESPONSE | grep 'ERROR')" ]; then
		echo "=> [PostgreSQL] Unable to drop table \"ip2location_database\""
		exit 1
	fi

	echo "=> [PostgreSQL] Rename table \"ip2location_database_tmp\" to \"ip2location_database\""

	RESPONSE="$(sudo -u postgres psql -c 'ALTER TABLE ip2location_database_tmp RENAME TO ip2location_database;' ip2location_database 2>&1)"

	if [ ! -z "$(echo $RESPONSE | grep 'ERROR')" ]; then
		echo "=> [PostgreSQL] Unable to rename table \"ip2location_database_tmp\""
		exit 1
	fi

	echo "=> [PostgreSQL] Update PostgreSQL password for user \"postgres\""

	if [ "$POSTGRESQL_PASSWORD" != "FALSE" ]; then
		DBPASS="$POSTGRESQL_PASSWORD"
	else
		DBPASS="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c8)"	
	fi

	sudo -u postgres psql -U postgres -d postgres -c "ALTER USER postgres WITH PASSWORD '$DBPASS';" > /dev/null
	sudo -u postgres psql -U postgres -d postgres -c 'DROP FUNCTION IF EXISTS inet_to_bigint(inet);CREATE OR REPLACE FUNCTION inet_to_bigint(inet) RETURNS bigint AS $$ SELECT $1 - inet '\''0.0.0.0'\'' $$ LANGUAGE SQL strict immutable;GRANT execute ON FUNCTION inet_to_bigint(inet) TO public;' > /dev/null

	echo "=> Setup completed"
	echo ""
	echo "=> You can now connect to this PostgreSQL Server using:"
	echo ""
	echo "   psql -h HOST -p PORT --username=postgres"
	echo "   Enter the password '$DBPASS' when prompted"
	echo ""

	rm -rf /_tmp
	echo '' > /setup_done
	service postgresql stop >/dev/null 2>&1
	sleep 5

	cd
fi

su postgres -c "/usr/lib/postgresql/9.3/bin/postgres -D /var/lib/postgresql/9.3/main -c config_file=/etc/postgresql/9.3/main/postgresql.conf 2> /var/log/postgresql/postgresql-9.3-main.log"