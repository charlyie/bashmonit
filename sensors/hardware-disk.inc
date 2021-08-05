#!/bin/bash
# Sensor for Bashmonit
# Has to return sensor_package and sensor_output variables (json).
# Since version : 1.0.x
# Updated in version : 1.2.2
#
# The MIT License (MIT)
# Copyright (c) 2021 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

sensor_package="hardware"

sensor_output=`printf '"disks": ['`
IFS=$'\n'
while read output;
do
	disk_usage=$(echo $output | awk 'END{print $6}')
	disk_free=$(echo $output | awk 'END{print $5"B"}')
	disk_total=$(echo $output | awk 'END{print $3"B"}')
	disk_device=$(echo $output | awk 'END{print $1}')
	mount_point=$(echo $output | awk 'END{print $7}')

	disk_data=$(printf '{"mount_point":"%s", "free":"%s", "total":"%s", "usage":"%s", "device":"%s"}' "$mount_point" "$disk_free" "$disk_total" "$disk_usage" "$disk_device")
	sensor_output="${sensor_output}${disk_data},"
done <<< $(df -kTh | grep -E 'ext4|ext3|ntfs|vfat' | grep -v '/boot')

sensor_output="${sensor_output::-1}]"
