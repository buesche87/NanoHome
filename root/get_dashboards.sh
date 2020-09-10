#!/bin/bash

home="XieEaLmRk"
devmgr_uid="Uhzl9yRgk"
zsp_uid="_H3fwdmRz"
settings_uid="sYOGRUiRz"

curl -X GET -H "Authorization: Bearer eyJrIjoiWk9YZDVmbGhRMkpmYjdsT3h3VjhSVjR5cXlwZUh1d3MiLCJuIjoiY3JlYXRlX2VsZW1lbnRzIiwiaWQiOjF9" -H "Content-Type: application/json" http://localhost:3001/api/dashboards/uid/XieEaLmRk > /root/home.temp.json
jq . /root/devmgmt.temp.json > /root/devmgmt.json
rm /root/devmgmt.temp.json

curl -X GET -H "Authorization: Bearer eyJrIjoiWk9YZDVmbGhRMkpmYjdsT3h3VjhSVjR5cXlwZUh1d3MiLCJuIjoiY3JlYXRlX2VsZW1lbnRzIiwiaWQiOjF9" -H "Content-Type: application/json" http://localhost:3001/api/dashboards/uid/Uhzl9yRgk > /root/devmgmt.temp.json
jq . /root/devmgmt.temp.json > /root/devmgmt.json
rm /root/devmgmt.temp.json

curl -X GET -H "Authorization: Bearer eyJrIjoiWk9YZDVmbGhRMkpmYjdsT3h3VjhSVjR5cXlwZUh1d3MiLCJuIjoiY3JlYXRlX2VsZW1lbnRzIiwiaWQiOjF9" -H "Content-Type: application/json" http://localhost:3001/api/dashboards/uid/_H3fwdmRz > /root/timer.temp.json
jq . /root/timer.temp.json > /root/timer.json
rm /root/timer.temp.json

curl -X GET -H "Authorization: Bearer eyJrIjoiWk9YZDVmbGhRMkpmYjdsT3h3VjhSVjR5cXlwZUh1d3MiLCJuIjoiY3JlYXRlX2VsZW1lbnRzIiwiaWQiOjF9" -H "Content-Type: application/json" http://localhost:3001/api/dashboards/uid/sYOGRUiRz> /root/settings.temp.json
jq . /root/settings.temp.json > /root/settings.json
rm /root/settings.temp.json

#while IFS= read -r line
#do
#	dev="$(cat /usr/local/nanohome/devlist | grep "$line" | cut -d: -f1 )"
#
#	sed -i 's/$dev//g' /root/devmgmt.json
#	sed -i 's/$dev//g' /root/timer.json
#	sed -i 's/$dev//g' /root/settings.json
#
#done < <(cat /usr/local/nanohome/devlist)
