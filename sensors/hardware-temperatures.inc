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

 # Get CPU Temp
count=0
sum=0.0
for temp in $(sensors | grep "^Core" | grep -e '+.*C' | cut -f 2 -d '+' | cut -f 1 -d ' ' | sed 's/°C//'); do
  sum=$(echo $sum+$temp | bc)
  count=$((count+1))
done
if [[ "$count" == "0" ]]; then
cpu_temp='N/A'
else  
cpu_temp=$(echo "$sum/$count" | bc)
fi

sensor_output=`printf '"temperatures": {"cpu":"%s"}' "$cpu_temp"`
