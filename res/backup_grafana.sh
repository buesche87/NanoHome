#!/bin/bash

set -e

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

current_path=$(dirname "$0")
settings_file="${1:-grafanaSettings}"
backup_dir="BACKUPDIR/Grafana"
timestamp=$(date +"%Y-%m-%dT%H-%M-%S")

if [[ ! -f "${current_path}/src/conf/${settings_file}.py" ]]; then
	echo "Usage:"
	echo "\t$0 <settings_file>"
	echo "\te.g. $1 'grafanaSettings'"
	exit 1
fi

[ -d "${backup_dir}" ] || mkdir -p "${backup_dir}"

for i in dashboards datasources folders alert_channels
do
	F="${backup_dir}/${i}/${timestamp}"
	[ -d "${F}" ] || mkdir -p "${F}"
	python3 "${current_path}/src/save_${i}.py" "${F}" "${settings_file}"
done

tar -czvf "${backup_dir}/${timestamp}.tar.gz" ${backup_dir}/{dashboards,datasources,folders,alert_channels}/${timestamp}
rm -rf ${backup_dir}/{dashboards,datasources,folders,alert_channels}/${timestamp}
