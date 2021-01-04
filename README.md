# NanoHome
Cloudless Retrofit Smarthome

Hardware: 

* [NanoPi NEO Air](https://www.friendlyarm.com/index.php?route=product/product&product_id=151m)
* [NanoHat OLED](https://www.friendlyarm.com/index.php?route=product/product&product_id=191)

Install:
* [Download](https://drive.google.com/file/d/15ZlfqEzKuynEtNOjQrP9ccKkO2nUi0pN/view?usp=sharing) Recovery-SD inkl. neustem NanoHome-Image
* SD-Karte mit Image flashen, SD einschieben und starten
* Per Knöpfe oder Webinterface (http://10.0.0.5) im Hotspot Modus ein Restore starten
* SD-Karte vor dem Reboot entfernen

Login:
* Gerät in Hotspot Modus setzen
* Mit NanoHome Wifi verbinden: `NanoHome_Log1n`
* https://10.0.0.5:3001 öffnen: `admin / login`

![home](https://i.ibb.co/CQb7KV8/nanohome-home.png)

Schalte deine Shellies/Sonoff mittels MQTT, auch ohne Internet

![devicemanager](https://i.ibb.co/6sNHJLB/nanohome-schaltuhr.png)

Miss den Stromverbrauch deiner Geräte

![devicemanager](https://i.ibb.co/jhY0jZG/nanohome-messungen.png)

Erstelle Carpet-Plots und überwache das Raumklima

![carpetplot](https://i.ibb.co/fSVf6QV/nanohome-carpetplot.png)

Guck Wetter (Nur, wenn dein Bediengerät Zugriff aufs Internet hat)

![carpetplot](https://i.ibb.co/f41Qnsq/nanohome-wetter.png)

Einfache Bedienung

![settings](https://i.ibb.co/mCdBhP3/nanohome-settings.png)

# Passwörter ändern

- Login mit `root / login`
- Passwort ändern: `passwd`

- Mosquitto & InfluxDB
  - `sudo mosquitto_passwd -c /etc/mosquitto/passwd mqtt_shell`
  - `sudo mosquitto_passwd -c /etc/mosquitto/passwd mqtt_bridge`
  - `influx user password -n mqtt_bridge`
    -> Anpassen von `usr/local/nanohome/driver/*`
	
  - `sudo mosquitto_passwd -c /etc/mosquitto/passwd multiswitch_mqtt`
  - `sudo mosquitto_passwd -c /etc/mosquitto/passwd cron_mqtt`
    -> Anpassen von `/usr/local/nanohome/services/*`

  - `sudo mosquitto_passwd -c /etc/mosquitto/passwd mqtt_grafana`
    -> Anpassen im Grafana "Status" HTML-Panel

- Grafana API Key ändern in `/usr/local/nanohome/bin/devmgmt`

- Geodaten für Wetter anpassen in den html-Dateien: `/usr/share/grafana/public/`

# Ungetestet

- Zigbee
