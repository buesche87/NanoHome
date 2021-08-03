# NanoHome

TBD


# Repositories

## InfluxDB (example debian buster)

```bash
curl -sL https://repos.influxdata.com/influxdb.key 133 | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian buster stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
```

## Grafana
```bash
sudo apt install -y apt-transport-https
sudo apt install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update
```

# Dependencies


## Install software
```bash
sudo apt install influxdb grafana mosquitto git python3
```
## Install dependencies
```bash
sudo apt install mosquitto-clients python3-pip python3-setuptools build-essential libfreetype6-dev libjpeg-dev jq openssl python3-influxdb python3-wheel python3-paho-mqtt
```

# unmask influxdb and start it
```bash
sudo systemctl unmask influxdb.service
sudo service influxdb start
```

# Installation
```bash
git clone
cd nanohome
chmod +x ./install.sh
sudo ./install.sh
```
