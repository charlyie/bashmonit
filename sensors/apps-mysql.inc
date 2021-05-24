#!/bin/bash
# Sensor for Bashmonit
# Has to return sensor_package and sensor_output variables (json).
# Since version : 1.0.7
#
# The MIT License (MIT)
# Copyright (c) 2021 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

sensor_package="apps"

source "${SENSORS_PATH}/apps-mysql.conf"

if ! which mysql > /dev/null; then
	sensor_output=`printf '"mysql": {"status": "not installed"}'`
else
	mysql_status=$(mysqladmin -h ${MYSQL_HOST} ping --user=${MYSQL_USER} --password=${MYSQL_PASSWD}|grep alive|wc -l)

	if [[ $mysql_status == '1' ]]; then
		mysql_status="online"
	else
		mysql_status="offline"
	fi

	sensor_output=`printf '"mysql": {"status":"%s"}' "$mysql_status"`
fi



