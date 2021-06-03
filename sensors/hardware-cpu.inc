#!/bin/bash
# Sensor for Bashmonit
# Has to return sensor_package and sensor_output variables (json).
# Since version : 1.0.7
# Updated in version : 1.2.1
#
# The MIT License (MIT)
# Copyright (c) 2021 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

sensor_package="hardware"

cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
cpu_cores=$(nproc --all)
cpu_name=$(cat /proc/cpuinfo | grep 'model name' | uniq | sed  's/model name.*:\s*//')
cpu_frequency=$(grep 'cpu MHz' /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs | sed 's/\.[0-9.]*//g')

sensor_output=`printf '"cpu": {"model":"%s", "frequency":"%s", "cores":"%s", "usage":"%s"}' "$cpu_name" "$cpu_frequency" "$cpu_cores" "$cpu_usage"`