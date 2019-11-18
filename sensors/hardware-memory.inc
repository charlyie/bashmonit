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

# Memory Usage
memory_used=$(free -m | awk 'NR==2{printf "%sMB", $3 }')
memory_total=$(free -m | awk 'NR==2{printf "%sMB", $2 }')
memory_usage=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')

sensor_output=`printf '"memory": {"used":"%s", "total":"%s", "usage":"%s"}' "$memory_used" "$memory_total" "$memory_usage"`
