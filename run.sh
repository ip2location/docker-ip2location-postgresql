#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

USER_AGENT="Mozilla/5.0+(compatible; IP2Location/PostgreSQL-Docker; https://hub.docker.com/r/ip2location/postgresql)"
CODES=("DB1-LITE DB3-LITE DB5-LITE DB9-LITE DB11-LITE DB1 DB2 DB3 DB4 DB5 DB6 DB7 DB8 DB9 DB10 DB11 DB12 DB13 DB14 DB15 DB16 DB17 DB18 DB19 DB20 DB21 DB22 DB23 DB24 DB25 DB26")

PSQL_VERSION=$(psql -V | awk '{ print $3 }' | cut -d. -f1)

if [ -z "$(grep '0.0.0.0' /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf)" ]; then
	sed -i 's/^\#listen_addresses.*/listen_addresses = '\''*'\''/g' /etc/postgresql/$PSQL_VERSION/main/postgresql.conf
	echo "host	all	all	0.0.0.0/0	md5" >> /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf
fi

if [ -f /ip2location.conf ]; then
	service postgresql start >/dev/null 2>&1
	tail -f /dev/null
fi

if [ "$TOKEN" == "FALSE" ]; then
	error "Missing download token."
fi

if [ "$CODE" == "FALSE" ]; then
	error "Missing database code."
fi

if [ "$POSTGRESQL_PASSWORD" == "FALSE" ]; then
	POSTGRESQL_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})"
fi

FOUND=""
for i in "${CODES[@]}"; do
	if [ "$i" == "$CODE" ] ; then
		FOUND="$CODE"
	fi
done

if [ -z $FOUND == "" ]; then
	error "Download code is invalid."
fi

CODE=$(echo $CODE | sed 's/-//')

echo -n " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && error "[ERROR]" || success "[OK]"

cd /_tmp

echo -n " > Download IP2Location database "

if [ "$IP_TYPE" == "IPV6" ]; then
	wget -O ipv6.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv6.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv6.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
else
	wget -O ipv4.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv4.zip)" ] && error "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv4.zip)" ] && error "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && error "[FILE CORRUPTED]"
fi

success "[OK]"

for ZIP in $(ls | grep '.zip'); do
	CSV=$(unzip -l $ZIP | sort -nr | grep -Eio 'IP(V6)?.*CSV' | head -n 1)

	echo -n " > Decompress $CSV from $ZIP"

	unzip -oq $ZIP $CSV

	if [ ! -f $CSV ]; then
		error "[ERROR]"
	fi

	success "[OK]"
done

service postgresql start >/dev/null

echo -n ' > [PostgreSQL] Create database "ip2location_database" '

RESPONSE="$(sudo -u postgres createdb ip2location_database 2>&1)"

[ ! -z "$(echo $RESPONSE | grep 'FATAL')" ] && error '[ERROR]' || success '[OK]'

echo -n ' > [PostgreSQL] Create table "ip2location_database_tmp" '

case "$CODE" in
	DB1|DB1LITE )
		FIELDS=''
	;;
	DB2 )
		FIELDS=',isp varchar(255) NOT NULL'
	;;

	DB3|DB3LITE )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL'
	;;

	DB4 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL'
	;;

	DB5|DB5LITE )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL'
	;;

	DB6 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL'
	;;

	DB7 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
	;;

	DB8 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
	;;

	DB9|DB9LITE )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL'
	;;

	DB10 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
	;;

	DB11|DB11LITE )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL'
	;;

	DB12 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
	;;

	DB13 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,time_zone varchar(8) NULL DEFAULT NULL,net_speed varchar(8) NOT NULL'
	;;

	DB14 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL'
	;;

	DB15 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL'
	;;

	DB16 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL'
	;;

	DB17 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,time_zone varchar(8) NULL DEFAULT NULL,net_speed varchar(8) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL'
	;;

	DB18 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL'
	;;

	DB19 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL'
	;;

	DB20 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL'
	;;

	DB21 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,elevation integer NOT NULL'
	;;

	DB22 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,elevation integer NOT NULL'
	;;

	DB23 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,usage_type varchar(11) NOT NULL'
	;;

	DB24 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,elevation integer NOT NULL,usage_type varchar(11) NOT NULL'
	;;

	DB25 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,elevation integer NOT NULL,usage_type varchar(11) NOT NULL,address_type char(1) NOT NULL,category varchar(10) NOT NULL'
	;;
	
	DB26 )
		FIELDS=',region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,latitude varchar(20) NOT NULL,longitude varchar(20) NOT NULL,zip_code varchar(30) NULL DEFAULT NULL,time_zone varchar(8) NULL DEFAULT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,net_speed varchar(8) NOT NULL,idd_code varchar(5) NOT NULL,area_code varchar(30) NOT NULL,weather_station_code varchar(10) NOT NULL,weather_station_name varchar(128) NOT NULL,mcc varchar(128) NULL DEFAULT NULL,mnc varchar(128) NULL DEFAULT NULL,mobile_brand varchar(128) NULL DEFAULT NULL,elevation integer NOT NULL,usage_type varchar(11) NOT NULL,address_type char(1) NOT NULL,category varchar(10) NOT NULL,district varchar(128) NOT NULL,asn varchar(10) NOT NULL,"as" varchar(256) NOT NULL,"as_domain" varchar(128) NOT NULL,"as_usage_type" varchar(11) NOT NULL,"as_cidr" varchar(43) NOT NULL'
	;;

	PX1|PX1LITECSV )
		FIELDS=',country_code char(2) NOT NULL,country_name varchar(64) NOT NULL'
	;;

	PX2|PX2LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL'
	;;

	PX3|PX3LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL'
	;;

	PX4|PX4LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL'
	;;

	PX5|PX5LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL'
	;;

	PX6|PX6LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,usage_type varchar(11) NOT NULL'
	;;

	PX7|PX7LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,usage_type varchar(11) NOT NULL,asn varchar(6) NOT NULL,"as" varchar(256)'
	;;

	PX8|PX8LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,usage_type varchar(11) NOT NULL,asn varchar(6) NOT NULL,"as" varchar(256),last_seen integer NOT NULL'
	;;

	PX9|PX9LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,usage_type varchar(11) NOT NULL,asn varchar(6) NOT NULL,"as" varchar(256),last_seen integer NOT NULL,threat varchar(128) NOT NULL'
	;;

	PX10|PX10LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,usage_type varchar(11) NOT NULL,asn varchar(6) NOT NULL,"as" varchar(256),last_seen integer NOT NULL,threat varchar(128) NOT NULL'
	;;

	PX11|PX11LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,usage_type varchar(11) NOT NULL,asn varchar(6) NOT NULL,"as" varchar(256),last_seen integer NOT NULL,threat varchar(128) NOT NULL,provider varchar(256) NOT NULL'
	;;
	
	PX12|PX12LITECSV )
		FIELDS=',proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL,country_name varchar(64) NOT NULL,region_name varchar(128) NOT NULL,city_name varchar(128) NOT NULL,isp varchar(255) NOT NULL,domain varchar(128) NOT NULL,usage_type varchar(11) NOT NULL,asn varchar(6) NOT NULL,"as" varchar(256),last_seen integer NOT NULL,threat varchar(128) NOT NULL,provider varchar(256) NOT NULL,fraud_score integer NOT NULL'
	;;
esac

RESPONSE="$(sudo -u postgres psql -c 'CREATE TABLE ip2location_database_tmp (ip_from decimal(39,0) NOT NULL,ip_to decimal(39,0) NOT NULL,country_code character(2) NOT NULL,country_name varchar(64) NOT NULL '"$FIELDS"', CONSTRAINT idx_key PRIMARY KEY (ip_to));' ip2location_database 2>&1)"

[ -z "$(echo $RESPONSE | grep 'CREATE TABLE')" ] && error '[ERROR]' || success '[OK]'

for CSV in $(ls | grep -i '.CSV'); do
	echo -n " > [PostgreSQL] Load $CSV into database "
	RESPONSE=$(sudo -u postgres psql -c 'COPY ip2location_database_tmp FROM '\''/_tmp/'$CSV''\'' WITH CSV QUOTE AS '\''"'\'';' ip2location_database 2>&1)

	[ -z "$(echo $RESPONSE | grep 'COPY')" ] && error '[ERROR]' || success '[OK]'
done

echo -n ' > [PostgreSQL] Rename table "ip2location_database_tmp" to "ip2location_database" '

RESPONSE="$(sudo -u postgres psql -c 'ALTER TABLE ip2location_database_tmp RENAME TO ip2location_database;' ip2location_database 2>&1)"

[ ! -z "$(echo $RESPONSE | grep 'ERROR')" ] &&  error '[ERROR]' || success '[OK]'

sudo -u postgres psql -d ip2location_database -c "CREATE FUNCTION ip2int(inet) RETURNS bigint AS \$\$ SELECT \$1 - '0.0.0.0'::inet \$\$ LANGUAGE SQL strict immutable;GRANT execute ON FUNCTION ip2int(inet) TO public;" > /dev/null
sudo -u postgres psql -d postgres -c "ALTER USER postgres WITH PASSWORD '$POSTGRESQL_PASSWORD';" > /dev/null

echo "  > Setup completed"
echo ""
echo "  > You can now connect to this PostgreSQL Server using:"
echo ""
echo "   psql -h HOST -p PORT --username=postgres"
echo "   Password: $POSTGRESQL_PASSWORD"
echo ""

rm -rf /_tmp

echo "POSTGRESQL_PASSWORD=$POSTGRESQL_PASSWORD" > /ip2location.conf
echo "TOKEN=$TOKEN" >> /ip2location.conf
echo "CODE=$CODE" >> /ip2location.conf
echo "IP_TYPE=$IP_TYPE" >> /ip2location.conf

cd /

service postgresql start >/dev/null 2>&1

tail -f /dev/null