#!/bin/bash
# Sensor for Bashmonit
# Has to return sensor_package and sensor_output variables (json).
# Since version : 1.0.7
#
# The MIT License (MIT)
# Copyright (c) 2021 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

sensor_package="system"

load_average=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}' )
processes_total=$(ps -e | wc |awk '{printf "%s", $1}')

biggest_process_usage=$(ps -eo pcpu,pid,user,args | sort -k 1 -r | head -2 | awk 'NR==2{printf "%s%%", $1 }')
biggest_process_command=$(ps -eo pcpu,pid,user,args | sort -k 1 -r | head -2 | awk 'NR==2{printf "%s", $4 }')
biggest_process_pid=$(ps -eo pcpu,pid,user,args | sort -k 1 -r | head -2 | awk 'NR==2{printf "%s", $2 }')

sensor_output=`printf '"processes": {"load_average": "%s", "count": "%s", "biggest": {"command":"%s", "pid":"%s", "cpu_usage":"%s"} }' "$load_average" "$processes_total" "$biggest_process_command" "$biggest_process_pid" "$biggest_process_usage"`
