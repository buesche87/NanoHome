#!/bin/bash

mount -t auto -v /dev/mmcblk1p2 /mnt/recovery_sd

cd /root/grafana-backup-tool/
./backup_grafana.sh "/mnt/recovery_sd/Backup/Grafana"
cp /etc/wpa_supplicant/wpa_supplicant* /mnt/recovery_sd/root/Backup/wpa_supplicant/
influxd backup -portable -database NanoPi /mnt/recovery_sd/root/Backup/InfluxDB

umount /mnt/recovery_sd
