#!/bin/bash
# Sensor for Bashmonit
# Has to return sensor_package and sensor_output variables (json).
# Since version : 1.2.13
#
# The MIT License (MIT)
# Copyright (c) 2021 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

sensor_package="hardware"

sensor_output=`printf '"disks": ['`
IFS=$'\n'
for i in $(lsblk | grep -E "disk" | awk '{print $1}')
do
	disk_temperature=`smartctl -a /dev/$i | awk '/Temperature/{print $0}' | awk '{print $10}'`
	disk_serial=`smartctl -a /dev/$i | awk '/Serial Number:/{print $0}' | awk '{print $3}'`
	disk_model_family=`smartctl -a /dev/$i | awk '/Model Family:/{print $0}' | sed -En "s/Model Family: //p" | xargs`
	disk_model=`smartctl -a /dev/$i | awk '/Device Model:/{print $0}' | sed -En "s/Device Model: //p" | xargs`
	disk_capacity=`smartctl -a /dev/$i | awk '/User Capacity:/{print $0}' | cut -d "[" -f2 | cut -d "]" -f1`
	disk_smart_status=`smartctl -a /dev/$i | awk '/SMART overall-health/{print $0}' | awk '{print $6}'`

	disk_data=$(printf '{"disk":"%s", "serial":"%s", "temperature":%d, "family_model":"%s", "model":"%s", "capacity":"%s", "smart_status":"%s"}' "/dev/$i" "$disk_serial" "$disk_temperature" "$disk_model_family" "$disk_model" "$disk_capacity" "$disk_smart_status")
	sensor_output="${sensor_output}${disk_data},"
done

sensor_output="${sensor_output::-1}]"