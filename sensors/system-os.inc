#!/bin/bash
# Sensor for Bashmonit
# Has to return sensor_package and sensor_output variables (json).
# Since version : 1.0.7
# Updated in version : 1.2.12
#
# The MIT License (MIT)
# Copyright (c) 2021 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

sensor_package="system"

# Get hostname
hostname=`hostname -a` 2> /dev/null

# Get distro
if which "python" > /dev/null; then
	distro=`python -c 'import platform ; print platform.linux_distribution()[0]'` 2> /dev/null
	distro_version=`python -c 'import platform ; print platform.linux_distribution()[1]'` 2> /dev/null
else
	distro=$(lsb_release -i | awk '{print $3}')
	if [ -f "/etc/debian_version" ]; then
		distro_version=$(cat /etc/debian_version)
	else
		distro_version=$(lsb_release -r | awk '{print $2}')
	fi
fi
# Get uptime
if [ -f "/proc/uptime" ]; then
	uptime=`cat /proc/uptime`
	uptime=${uptime%%.*}
	seconds=$(( uptime%60 ))
	minutes=$(( uptime/60%60 ))
	hours=$(( uptime/60/60%24 ))
	days=$(( uptime/60/60/24 ))
	uptime="$days days, $hours hours, $minutes minutes, $seconds seconds"
	uptime_timestamp=$(date -d "$(who -b | awk '{print $4,$3}' | tr - / )" +%s)
else
	uptime=""
fi

sensor_output=`printf '"os": {"hostname":"%s", "distro":"%s", "distro_version":"%s", "uptime":"%s", "uptime_timestamp":%d}' "$hostname" "$distro" "$distro_version" "$uptime" "$uptime_timestamp"` 
