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

if ! which php > /dev/null; then
	sensor_output=`printf '"php": {"version": "not installed"}'`
else
	php_version=$(echo "<?php echo phpversion();" | php)
	sensor_output=`printf '"php": {"version":"%s"}' "$php_version"`
fi