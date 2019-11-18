#!/bin/bash
# Sensor for Bashmonit
# Has to return sensor_package and sensor_output variables (json).
# Since version : 1.0.7
#
# The MIT License (MIT)
# Copyright (c) 2017 Charles Bourgeaux <contact@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

sensor_package="hardware"

# Get Usage Disk
disk_usage=$(df / | awk 'END{print $5}')
disk_free=$(df -h / | awk 'END{print $4}')
disk_total=$(df -h / | awk 'END{print $2}')

sensor_output=`printf '"disk": {"free":"%s", "total":"%s", "usage":"%s"}' "$disk_free" "$disk_total" "$disk_usage"`
