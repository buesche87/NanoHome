#!/bin/bash
######################################
# NanoHome Automation Server Install
######################################

if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root. Try 'sudo ./install.sh'\n"
  exit 1
fi

# load settings
. ./config.cfg

# test if user exists

if getent passwd $linuxuser > /dev/null ; then
 
 echo "use existing user \"$linuxuser\""

else

 echo "create user $linuxuser"
 useradd -p $(openssl passwd -1 $linuxpass) $linuxuser

fi

# create directories

 mkdir -p $rootpath/bin/
 mkdir -p $rootpath/conf/
 mkdir -p $rootpath/driver/
 mkdir -p $rootpath/sensor/
 mkdir -p $rootpath/template/
 mkdir -p $backupdir

 touch $rootpath/devlist
 touch $rootpath/killerlist ## still necessary?
 touch $rootpath/switchlist ## still necessary?


# general

 touch $rootpath/devlist
 cp ./config.cfg $rootpath
 cp ./dev_compatibility $rootpath
 cp ./template/* $rootpath/template/

 sed -i "s#INSTALLDIR#$rootpath#" $rootpath/*

# prepare influxdb database

 influx -execute "CREATE DATABASE ${influxdb_database}"
 influx -execute "CREATE USER ${influxdb_admin} WITH PASSWORD '${influxdb_adminpass}' WITH ALL PRIVILEGES"
 influx -execute "CREATE USER ${influxdb_system_user} WITH PASSWORD '${influxdb_system_pass}'"
 influx -execute "GRANT ALL ON ${influxdb_database} TO ${influxdb_system_user}"

# configure mosquitto

 touch /etc/mosquitto/conf.d/nanohome.conf
 echo password_file /etc/mosquitto/passwd > /etc/mosquitto/conf.d/nanohome.conf
 echo allow_anonymous false >> /etc/mosquitto/conf.d/nanohome.conf
 echo listener 1883 >> /etc/mosquitto/conf.d/nanohome.conf
 echo listener 1884 >> /etc/mosquitto/conf.d/nanohome.conf
 echo protocol websockets >> /etc/mosquitto/conf.d/nanohome.conf

# create mosquitto user

 touch /etc/mosquitto/passwd
 mosquitto_passwd -U /etc/mosquitto/passwd
 mosquitto_passwd -b /etc/mosquitto/passwd $mqtt_system_user $mqtt_system_pass

# create mosquitto user for external access

 mosquitto_passwd -b /etc/mosquitto/passwd $mqtt_grafana_user $mqtt_grafana_pass
 mosquitto_passwd -b /etc/mosquitto/passwd $mqtt_shelly_user $mqtt_shelly_pass
 mosquitto_passwd -b /etc/mosquitto/passwd $mqtt_dash_user $mqtt_dash_pass

# copy binaries & make executable

 cp ./bin/* $rootpath/bin/
 chmod +x $rootpath/bin/*
 ln -sf $rootpath/bin/* /usr/local/bin/

 sed -i "s#INSTALLDIR#$rootpath#" $rootpath/bin/*

# copy drivers

 cp ./driver/* $rootpath/driver/
 chmod +x $rootpath/driver/*

 sed -i "s#INSTALLDIR#$rootpath#" $rootpath/driver/*
 sed -i "s#INFLUXDATABASE#$influxdb_database#" $rootpath/driver/*
 sed -i "s#DATABASEUSER#$influxdb_system_user#" $rootpath/driver/*
 sed -i "s#DATABASEPASS#$influxdb_system_pass#" $rootpath/driver/*
 sed -i "s#MQTTSYSTEMUSER#$mqtt_system_user#" $rootpath/driver/*
 sed -i "s#MQTTSYSTEMPASS#$mqtt_system_pass#" $rootpath/driver/*
 
# create services

 cp ./service/* /etc/systemd/system/
 sed -i "s#INSTALLDIR#$rootpath#" /etc/systemd/system/mqtt_*
 sed -i "s#SVCUSER#$linuxuser#" /etc/systemd/system/mqtt_*

 
# create cputemp sensor

 if $cputemp ; then 
 
  cp ./sensor/cputemp $rootpath/sensor/cputemp
  chmod +x $rootpath/sensor/cputemp
  
  ( crontab -l -u $linuxuser | grep -v -F "$rootpath/sensor/cputemp" ; echo "*/5 * * * * $rootpath/sensor/cputemp" ) | crontab -u nanohome -
 
 fi
 
 # create diskspace sensor
 
 if $diskspace ; then
 
  cp ./sensor/diskspace $rootpath/sensor/diskspace
  chmod +x $rootpath/sensor/diskspace
 
  ( crontab -l -u $linuxuser | grep -v -F "$rootpath/sensor/diskspac" ; echo "* */1 * * * $rootpath/sensor/diskspace" ) | crontab -u nanohome -
 
 fi

 sed -i "s#INSTALLDIR#$rootpath#" $rootpath/sensor/*

# Grafana setup


# copy ressources
 
 cp -R ./res/* /usr/share/grafana/public/
 sed -i "s#;disable_sanitize_html.*#disable_sanitize_html = true#g" /etc/grafana/grafana.ini
 
# create datasource
 
  generate_datasource()
{
  cat <<EOF
{
  "name":"InfluxDB",
  "type":"influxdb",
  "url":"http://localhost:8086",
  "user":"$influxdb_system_user",
  "password":"$influxdb_system_pass",
  "database":"$influxdb_database",
  "access":"proxy",
  "isDefault":true,
  "readOnly":false
}
EOF
}
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST --data "$(generate_datasource)" "http://admin:admin@$grafana_url/api/datasources"
 
# create api key
 
 api_json="$(curl -X POST -H "Content-Type: application/json" -d '{"name":"Nanohome System", "role": "Admin"}' http://admin:admin@$grafana_url/api/auth/keys)"
 echo "$api_json" | sudo tee $rootpath/conf/api_key.json
 api_key="$(echo "$api_json" | jq -r '.key')"
 
# create folders

 curl -X POST -H "Content-Type: application/json" -d '{"id":1, "title":"NanoHome"}' http://admin:admin@$grafana_url/api/folders
 curl -X POST -H "Content-Type: application/json" -d '{"id":2, "title":"Settings"}' http://admin:admin@$grafana_url/api/folders 
 
# create dashboards 
 
 cp ./dashboards/* /tmp/
 home_json_data="{ \"folderId\": 1, \"overwrite\": true }"
 settings_json_data="{ \"folderId\": 2, \"overwrite\": true }"
 
# home

 sed -i 's#var user = \\\"\\\"#var user = \\\"'$mqtt_grafana_user'\\\"#' /tmp/home.json
 sed -i 's#var pwd = \\\"\\\"#var pwd = \\\"'$mqtt_grafana_pass'\\\"#' /tmp/home.json
 
 # sed -i 's#var user = \\\"\\\"#var user = \\\"'$location'\\\"#' /tmp/timer.json   --> Weather Location

 jq --argjson options "$home_json_data" '. += $options' /tmp/home.json > /tmp/home_final.json

 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/home_final.json "http://admin:admin@$grafana_url/api/dashboards/db"
 

# devicemanager

 jq --argjson options "$settings_json_data" '. += $options' /tmp/devicemanager.json > /tmp/devicemanager_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/devicemanager_final.json "http://admin:admin@$grafana_url/api/dashboards/db"
 
# measurements

 jq --argjson options "$home_json_data" '. += $options' /tmp/measurements.json > /tmp/measurements_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/measurements_final.json "http://admin:admin@$grafana_url/api/dashboards/db"
 
# settings

 sed -i 's#var user = \\\"\\\"#var user = \\\"'$mqtt_grafana_user'\\\"#' /tmp/settings.json
 sed -i 's#var pwd = \\\"\\\"#var pwd = \\\"'$mqtt_grafana_pass'\\\"#' /tmp/settings.json

 jq --argjson options "$settings_json_data" '. += $options' /tmp/settings.json > /tmp/settings_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/settings_final.json "http://admin:admin@$grafana_url/api/dashboards/db"

# system

 jq --argjson options "$settings_json_data" '. += $options' /tmp/system.json > /tmp/system_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/system_final.json "http://admin:admin@$grafana_url/api/dashboards/db"   
 
# timer

 sed -i 's#var user = \\\"\\\"#var user = \\\"'$mqtt_grafana_user'\\\"#' /tmp/timer.json
 sed -i 's#var pwd = \\\"\\\"#var pwd = \\\"'$mqtt_grafana_pass'\\\"#' /tmp/timer.json

 jq --argjson options "$home_json_data" '. += $options' /tmp/timer.json > /tmp/timer_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/timer_final.json "http://admin:admin@$grafana_url/api/dashboards/db"

# weather

 # sed -i 's#var user = \\\"\\\"#var user = \\\"'$location'\\\"#' /tmp/timer.json   --> Weather Location

 jq --argjson options "$settings_json_data" '. += $options' /tmp/weather.json > /tmp/weather_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/weather_final.json "http://admin:admin@$grafana_url/api/dashboards/db"   


# carpetplot

 jq --argjson options "$home_json_data" '. += $options' /tmp/carpetplot.json > /tmp/carpetplot_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/carpetplot_final.json "http://admin:admin@$grafana_url/api/dashboards/db"   

# change home dashboards

 home_id="$(curl -X GET -H "Authorization: Bearer $api_key" -H "Content-Type: application/json" http://$grafana_url/api/dashboards/uid/$home_uid | jq -r '.dashboard.id')"
 curl -X PUT -H "Content-Type: application/json" -d '{"homeDashboardId":'$home_id'}' http://admin:admin@$grafana_url/api/org/preferences

# install grafana backup

 pip3 install "pip>=20"

 git clone https://github.com/ysde/grafana-backup-tool.git $rootpath/grafana-backup-tool

 cd $rootpath/grafana-backup-tool
 pip3 install $rootpath/grafana-backup-tool
 cd -
 
 gbt_conf="$rootpath/grafana-backup-tool/grafana_backup/conf/grafanaSettings.json"

 echo "$( jq '.grafana.token = "'$api_key'"' $gbt_conf )" > $gbt_conf
 echo "$( jq '.general.backup_dir = "'$backupdir'"' $gbt_conf )" > $gbt_conf
 echo "$( jq '.general.verify_ssl = false' $gbt_conf )" > $gbt_conf

 sed -i "s#python#python3#" $rootpath/grafana-backup-tool/backup_grafana.sh
 sed -i "s#python#python3#" $rootpath/grafana-backup-tool/restore_grafana.sh


 
# post processing
 
 rm -rf /tmp/*.json
 chown -R $linuxuser:$linuxuser $rootpath
 
 /usr/share/grafana/bin/grafana-cli plugins install grafana-clock-panel
 /usr/share/grafana/bin/grafana-cli plugins install petrslavotinek-carpetplot-panel

# start services

 systemctl restart influxdb
 systemctl restart grafana-server
 systemctl restart mosquitto
 systemctl start mqtt_shell.service
 systemctl enable mqtt_shell.service
 systemctl start mqtt_bridge_home.service
 systemctl enable mqtt_bridge_home.service
 systemctl start mqtt_bridge_shelly.service
 systemctl enable mqtt_bridge_shelly.service
 systemctl start mqtt_bridge_shellyht.service
 systemctl enable mqtt_bridge_shellyht.service
 
