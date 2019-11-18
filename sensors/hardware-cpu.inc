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

cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
cpu_cores=$(nproc --all)

sensor_output=`printf '"cpu": {"usage":"%s", "cores":"%s"}' "$cpu_usage" "$cpu_cores"`