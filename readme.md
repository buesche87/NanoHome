# NanoHome

This is a one-man show, don't expect it to be bug-free...

I used https://dietpi.com as distribution

You can install NanoHome on a virtual machine, Raspberry Pi or any another SBC. 
The following steps should be everything you need on a debian based distro for it to start.

# Repositories

## InfluxDB (example debian bullseye)

```bash
wget -qO- https://repos.influxdata.com/influxdb.key | gpg --dearmor > /etc/apt/trusted.gpg.d/influxdb.gpg
sudo echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdb.gpg] https://repos.influxdata.com/debian bullseye stable" > /etc/apt/sources.list.d/influxdb.list
```

## Grafana
```bash
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
```

# Dependencies


## Install software
```bash
sudo apt update
sudo apt install influxdb grafana mosquitto git python3
```

## Install dependencies
```bash
sudo apt install mosquitto-clients python3-pip python3-setuptools build-essential libfreetype6-dev libjpeg-dev jq openssl python3-influxdb python3-wheel python3-paho-mqtt tree
```

# unmask influxdb and start it
```bash
sudo systemctl unmask influxdb.service
sudo service influxdb start
```

## Install NanoHome

# Clone NanoHome
```bash
git clone https://github.com/buesche87/NanoHome.git
```

# Edit NanoHome Config

Copy `config.cfg.example` to `config.cfg`.

Edit username and password entries. Don't mess with the dashboard settings, these id's are given by the installation.

# Install

```bash
cd NanoHome
chmod +x ./install.sh
sudo ./install.sh
```

Start your Webbroser and go to http://ipaddress:3000/
