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

if getent passwd $username > /dev/null ; then
 
 echo "use existing user \"$username\""

else

 echo "create user $username"
 useradd -p $(openssl passwd -1 $userpass) $username

fi

# create directories

 mkdir -p $rootpath/bin/
 mkdir -p $rootpath/conf/
 mkdir -p $rootpath/driver/
 mkdir -p $rootpath/sensor/
 mkdir -p $rootpath/template/
 mkdir -p $backupdir

 touch $rootpath/devlist
 touch $rootpath/killerlist
 touch $rootpath/switchlist


# general

 touch $rootpath/devlist
 cp ./dev_compatibility $rootpath
 cp ./template/* $rootpath/template/
 echo "%$username ALL=NOPASSWD: /bin/systemctl restart nanohome_helper" > /etc/sudoers.d/nanohome

# prepare influxdb database

 influx -execute "CREATE DATABASE $influxdb_name"
 influx -execute "CREATE USER ${influxdb_admin} WITH PASSWORD '${influxdb_adminpass}' WITH ALL PRIVILEGES"
 influx -execute "CREATE USER ${influx_system_user} WITH PASSWORD '${influx_system_pass}'"
 influx -execute "GRANT ALL ON ${influxdb_name} TO ${influx_system_user}"

# create mosquitto user

 touch /etc/mosquitto/passwd
 mosquitto_passwd -b /etc/mosquitto/passwd $mqtt_system_user $mqtt_system_pass

# create mosquitto user for external access

 mosquitto_passwd -b /etc/mosquitto/passwd $mqtt_grafana_user $mqtt_grafana_pass
 mosquitto_passwd -b /etc/mosquitto/passwd $mosquitto_shelly_user $mosquitto_shelly_pass
 mosquitto_passwd -b /etc/mosquitto/passwd $mosquitto_dash_user $mosquitto_dash_pass

# configure mosquitto

 touch /etc/mosquitto/conf.d/nanohome.conf
 echo listener 1883 >> /etc/mosquitto/conf.d/nanohome.conf
 echo listener 1884 >> /etc/mosquitto/conf.d/nanohome.conf
 echo protocol websockets >> /etc/mosquitto/conf.d/nanohome.conf

# copy binaries & make executable

 cp ./bin/* $rootpath/bin/
 chmod +x $rootpath/bin/*
 ln -sf $rootpath/bin/* /usr/local/bin/

 sed -i "s#INSTALLDIR#$rootpath#" $rootpath/bin/*
 sed -i "s#BACKUPDIR#$backupdir#" $rootpath/bin/*
 sed -i "s#MQTTSYSTEMUSER#$mqtt_system_user#" $rootpath/bin/*
 sed -i "s#MQTTSYSTEMPASS#$mqtt_system_pass#" $rootpath/bin/*
 sed -i "s#INFLUXDATABASE#$influxdb_name#" $rootpath/bin/*

# copy drivers

 cp ./driver/* $rootpath/driver/
 chmod +x $rootpath/driver/*

 sed -i "s#INSTALLDIR#$rootpath#" $rootpath/driver/*
 sed -i "s#MQTTSYSTEMUSER#$mqtt_system_user#" $rootpath/driver/*
 sed -i "s#MQTTSYSTEMPASS#$mqtt_system_pass#" $rootpath/driver/*
 sed -i "s#DATABASEUSER#$influx_system_user#" $rootpath/driver/*
 sed -i "s#DATABASEPASS#$influx_system_pass#" $rootpath/driver/*
 sed -i "s#INFLUXDATABASE#$influxdb_name#" $rootpath/bin/*
 
# create services

 cp ./service/* /lib/systemd/system/
 sed -i "s#INSTALLDIR#$rootpath#" /lib/systemd/system/mqtt_*
 sed -i "s#INSTALLDIR#$rootpath#" /lib/systemd/system/nanohome*
 sed -i "s#SVCUSER#$username#" /lib/systemd/system/mqtt_*

# modify device manager
 
 touch /opt/nanohome/conf/uids
 echo "home_uid:$home_uid" >> /opt/nanohome/conf/uids
 echo "devmgr_uid:$devmgr_uid" >> /opt/nanohome/conf/uids
 echo "zsp_uid:$zsp_uid" >> /opt/nanohome/conf/uids
 echo "settings_uid:$settings_uid" >> /opt/nanohome/conf/uids

# create cputemp sensor

 if $cputemp ; then 
 
  cp ./sensor/cputemp $rootpath/bin/cputemp
  sed -i "s#INFLUXDATABASE#$influxdb_name#" $rootpath/bin/cputemp
  chmod +x $rootpath/bin/cputemp
  
  ( crontab -l -u $username | grep -v -F "$rootpath/bin/cputemp" ; echo "*/5 * * * * $rootpath/bin/cputemp" ) | crontab -u nanohome -
 
 fi
 
 # create diskspace sensor
 
 if $diskspace ; then
 
  cp ./sensor/diskspace $rootpath/bin/diskspace
  sed -i "s#INFLUXDATABASE#$influxdb_name#" $rootpath/bin/diskspace
  chmod +x $rootpath/bin/diskspace
 
  ( crontab -l -u $username | grep -v -F "$rootpath/bin/diskspac" ; echo "* */1 * * * $rootpath/bin/diskspace" ) | crontab -u nanohome -
 
 fi


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
  "user":"$influx_system_user",
  "password":"$influx_system_pass",
  "database":"$influxdb_name",
  "access":"proxy",
  "isDefault":true,
  "readOnly":false
}
EOF
}
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST --data "$(generate_datasource)" "http://admin:admin@localhost:3000/api/datasources"
 
# create api key
 
 api_json="$(curl -X POST -H "Content-Type: application/json" -d '{"name":"Nanohome System", "role": "Admin"}' http://admin:admin@localhost:3000/api/auth/keys)"
 echo "$api_json" | sudo tee -a $rootpath/conf/api_key.json
 api_key="$(echo "$api_json" | jq -r '.key')"
 
# create folders

 curl -X POST -H "Content-Type: application/json" -d '{"id":1, "title":"NanoHome"}' http://admin:admin@localhost:3000/api/folders
 curl -X POST -H "Content-Type: application/json" -d '{"id":2, "title":"Settings"}' http://admin:admin@localhost:3000/api/folders 
 
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
 -X POST -d @/tmp/home_final.json "http://admin:admin@localhost:3000/api/dashboards/db"
 

# devicemanager

 jq --argjson options "$settings_json_data" '. += $options' /tmp/devicemanager.json > /tmp/devicemanager_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/devicemanager_final.json "http://admin:admin@localhost:3000/api/dashboards/db"
 
# measurements

 jq --argjson options "$home_json_data" '. += $options' /tmp/measurements.json > /tmp/measurements_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/measurements_final.json "http://admin:admin@localhost:3000/api/dashboards/db"
 
# settings

 sed -i 's#var user = \\\"\\\"#var user = \\\"'$mqtt_grafana_user'\\\"#' /tmp/settings.json
 sed -i 's#var pwd = \\\"\\\"#var pwd = \\\"'$mqtt_grafana_pass'\\\"#' /tmp/settings.json

 jq --argjson options "$settings_json_data" '. += $options' /tmp/settings.json > /tmp/settings_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/settings_final.json "http://admin:admin@localhost:3000/api/dashboards/db"

# system

 jq --argjson options "$settings_json_data" '. += $options' /tmp/system.json > /tmp/system_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/system_final.json "http://admin:admin@localhost:3000/api/dashboards/db"   
 
# timer

 sed -i 's#var user = \\\"\\\"#var user = \\\"'$mqtt_grafana_user'\\\"#' /tmp/timer.json
 sed -i 's#var pwd = \\\"\\\"#var pwd = \\\"'$mqtt_grafana_pass'\\\"#' /tmp/timer.json

 jq --argjson options "$home_json_data" '. += $options' /tmp/timer.json > /tmp/timer_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/timer_final.json "http://admin:admin@localhost:3000/api/dashboards/db"

# weather

 # sed -i 's#var user = \\\"\\\"#var user = \\\"'$location'\\\"#' /tmp/timer.json   --> Weather Location

 jq --argjson options "$settings_json_data" '. += $options' /tmp/weather.json > /tmp/weather_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/weather_final.json "http://admin:admin@localhost:3000/api/dashboards/db"   


# carpetplot

 jq --argjson options "$home_json_data" '. += $options' /tmp/carpetplot.json > /tmp/carpetplot_final.json
 
 curl -i \
 -H "Accept: application/json" \
 -H "Content-Type:application/json" \
 -X POST -d @/tmp/carpetplot_final.json "http://admin:admin@localhost:3000/api/dashboards/db"   

# change home dashboards

 home_id="$(curl -X GET -H "Authorization: Bearer $api_key" -H "Content-Type: application/json" http://localhost:3000/api/dashboards/uid/$home_uid | jq -r '.dashboard.id')"
 curl -X PUT -H "Content-Type: application/json" -d '{"homeDashboardId":'$home_id'}' http://admin:admin@localhost:3000/api/org/preferences

# install grafana backup

 pip3 install "pip>=20"

 git clone https://github.com/ysde/grafana-backup-tool.git $rootpath/grafana-backup-tool

 cd $rootpath/grafana-backup-tool
 pip3 install $rootpath/grafana-backup-tool
 cd -
 
 gbt_conf="$rootpath/grafana-backup-tool/grafana_backup/conf/grafanaSettings.json"

 echo "$( jq '.grafana.token = "'$api_key'"' $gbt_conf )" > $gbt_conf
 echo "$( jq '.general.backup_dir = "'$backupdir'"' $gbt_conf )" > $gbt_conf
 echo "$( '.general.verify_ssl = false' $gbt_conf )" > $gbt_conf

 sed -i "s#python#python3#" $rootpath/grafana-backup-tool/backup_grafana.sh
 sed -i "s#python#python3#" $rootpath/grafana-backup-tool/restore_grafana.sh


 
# post processing
 
 rm -rf /tmp/*.json
 chown -R $username:$username $rootpath
 
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
 
