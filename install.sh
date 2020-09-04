#!/bin/bash
######################################
# NanoHome Automation Server Install (Early Alpha Installer)

if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root. Try 'sudo ./install.sh'\n"
  exit 1
fi

# Install Software
wget http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key && sudo apt-key add mosquitto-repo.gpg.key && rm mosquitto-repo.gpg.key || (echo "Failed to add mosquitto repository" && set -e)
apt-get update
apt-get install mosquitto grafana influxdb

# Install dependencies
apt-get -y install mosquitto-clients python3 python3-pip python3-setuptools hostapd dnsmasq build-essential git libfreetype6-dev libjpeg-dev || (echo "Failed to install dependencies" && set -e)

systemctl disable dnsmasq hostapd wpa_supplicant
dietpi-services disable hostapd
dietpi-services disable dnsmasq

# Install Python Modules
pip3 install wheel paho-mqtt influxdb ssd1306 || (echo "Failed to install Python Modules" && set -e)

# Copy NanoHome Files
cp -R ./etc/* /etc/
cp -R ./usr/* /usr/

# Make NnaoHome Scripts executable
chmod +x /usr/local/nanohome/bin/*

# Start services
systemctl start autohotspot.service || (echo "Failed to start autohotspot service" && set -e)
systemctl enable autohotspot.service
systemctl start nanohatoled.service || (echo "Failed to start nanohatoled service" && set -e)
systemctl enable nanohatoled.service
systemctl start mqtt_shell.service || (echo "Failed to start mqtt_shell service" && set -e)
systemctl enable mqtt_shell.service
systemctl start mqtt_bridge_shellyht.service || (echo "Failed to start mqtt_bridge_shellyht service" && set -e)
systemctl enable mqtt_bridge_shellyht.service
systemctl start mqtt_bridge_shelly.service || (echo "Failed to start mqtt_bridge_shelly service" && set -e)
systemctl enable mqtt_bridge_shelly.service
systemctl start mqtt_bridge_home.service || (echo "Failed to start mqtt_bridge_home service" && set -e)
systemctl enable mqtt_bridge_home.service

# Install and configure InfluxDB
influx -execute 'CREATE DATABASE NanoPi' || (echo "Failed to create Influx Database" && set -e)
influx -execute 'CREATE USER admin WITH PASSWORD "DitoPI64" WITH ALL PRIVILEGES' || (echo "Failed to create Influx user admin" && set -e)
influx -execute 'CREATE USER mqtt_bridge WITH PASSWORD "MQTT2InfluxDB"' || (echo "Failed to create Influx user mqtt_bridge" && set -e)
influx -execute 'CREATE USER grafana WITH PASSWORD "InfluxDB2Grafana"' || (echo "Failed to create Influx user grafana" && set -e)
influx -execute 'GRANT ALL ON "NanoPi" TO "mqtt_bridge"' || (echo "Failed to grant privileges for Influx user mqtt_bridge" && set -e)
influx -execute 'GRANT ALL ON "NanoPi" TO "grafana"' || (echo "Failed to grant privileges for Influx user grafana" && set -e)

# Change dirty html in grafana
sed -i "s/;disable_sanitize_html.*/disable_sanitize_html = true/g" /etc/grafana/grafana.ini

# Grafana MQTT Jscript
wget https://cdnjs.cloudflare.com/ajax/libs/paho-mqtt/1.0.2/mqttws31.min.js -O /usr/share/grafana/public/ || (echo "Failed to get mqttws31.min.js" && set -e)

# Create CPU Temperature Monitoring
crontab -l | { cat; echo "*/1 * * * * /usr/local/nanohome/bin/cputemp"; } | crontab - || (echo "Failed to add cputemp crontab" && set -e)

# Create Free Disk Monitoring
crontab -l | { cat; echo "*/15 * * * * /usr/local/nanohome/bin/diskspace"; } | crontab - || (echo "Failed to add diskspace crontab" && set -e)

# Create IP Monitoring
crontab -l | { cat; echo "* */1 * * * /usr/local/nanohome/bin/ip_to_mqtt"; } | crontab - || (echo "Failed to add ip_mqtt crontab" && set -e)