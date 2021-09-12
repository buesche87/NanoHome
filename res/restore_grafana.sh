#!/bin/bash

set -e

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

current_path=$(dirname "$0")
archive_file="$(ls -t /mnt/recovery_sd/root/Backup/Grafana/*.tar.gz | head -1)"
settings_file="${2:-grafanaSettings}"

if [[ ! -f "${archive_file}" || ! -f "${current_path}/src/conf/${settings_file}.py" ]]; then
	echo "Usage:"
	echo "\t$0 <archive_file>"
	echo "\te.g. $0 '_OUTPUT_/2019-05-13T11-04-33.tar.gz'"
	echo "\t$1 <settings_file_name>"
	echo "\te.g. $1 'grafanaSettings'"
	exit 1
fi

tmp_dir="/tmp/restore_grafana.$$"
mkdir -p "$tmp_dir"
tar -xzf ${archive_file} -C $tmp_dir

for j in folder datasource dashboard alert_channel
do
	find ${tmp_dir} -type f -name "*.${j}" | while read f
	do
		python3 "${current_path}/src/create_${j}.py" "${f}" "${settings_file}"
	done
done

rm -rf $tmp_dir
