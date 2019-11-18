#!/bin/bash
# bashmonit.sh -- http://127.0.0.1:8080/?key=XXXX
# chmod 755 bashmonit.sh
# then run: ./bashmonit.sh
#
# Based on bashttp : webserver in bash
#
# The MIT License (MIT)
# Copyright (c) 2017 Charles Bourgeaux <hello@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.


PORT=80
VERSION="1.1.0"
BUILD_DATE="20170908"
REQUIRED_PACKAGES=( "nc" "awk" "netstat" "sensors" "bc")

HTTP_RESPONSE=/tmp/webresp
APP_DIR=$(dirname "$0")
SENSORS_PATH=/etc/bashmonit.d
LOG="/var/log/bashmonit.log"
INI="/etc/bashmonit.conf"
FIRST_RUN=false
QUIET=false


while getopts ':hvq' option
do
 case "${option}" in
  h)  printf "Bashmonit v.${VERSION}, server Monitoring tool, extensible with custom sensors, and outputing a JSON on a standalone HTTP server\n"
      printf "Usage: (as a daemon) /etc/init.d/bashmonit start\n"
      printf "Usage: (one shot) bashmonit\n"
      printf "Startup:\n"
      printf "  -h \t\t print this help.\n"
      printf "  -q \t\t run in QUIET mode.\n\n"
      printf "  -v \t\t display the version of Bashmonit.\n\n"
      printf "Logs:\n"
      printf "  Output \t /var/log/bashmonit.log\n\n"
      printf "Configuration:\n"
      printf "  General \t /etc/bashmonit.conf\n"
      printf "  Sensors \t /etc/bashmonit.d/*\n"
      exit 0
      ;;
  v)  echo "Bashmonit v.${VERSION} (build ${BUILD_DATE})"
      exit 0
      ;;  
  q)  QUIET=true
      ;;
  \?) echo "Invalid option: -$OPTARG. Type -h to show help" >&2 
      exit 0
      ;;
 esac
done

# Display output and save it to log file.
cli_output(){
  if $QUIET ; then
    echo "[`date '+%Y-%m-%d %H:%M:%S'`] $1" > ${LOG}
  else
    echo "[`date '+%Y-%m-%d %H:%M:%S'`] $1" | tee -a ${LOG}
  fi
}

cli_output "Starting daemon bashmonit..."
# Requires ROOT for NC
if [[ `id -u` -ne 0 ]]; then
  cli_output "This daemon needs ROOT privileges. Please log as root or use sudo."
  exit 0
fi


# Check required packages and try to install them
for x in ${REQUIRED_PACKAGES[@]}
do
if ! which $x > /dev/null; then
  cli_output "Missing package $x."
  echo -e "Try to install it ? (y/n) \c"
  if [[ "$x" == "sensors" ]]
    then
    x="lm-sensors"
  fi
  read
  if [[ "$REPLY" == "y" ]]; then
     if ! which sudo > /dev/null || ! which apt-get > /dev/null; then
      cli_output "Cannot install package '$x' automatically. Please install it manually."
      exit 0
    else
      sudo apt-get -qq update
      sudo apt-get -y -qq install $x 
    fi
  else
    cli_output "Some package are missing. Try to install them before."
    exit 0
  fi
fi
done

# On first launch create a configuration, otherwise, read from it
if [ ! -f "$INI" ]; then
  cli_output "Creating INI File..."
  FIRST_RUN=true
  KEY=`date +%s | sha256sum | base64 | head -c 32  | tr '[:lower:]' '[:upper:]'`
cat >$INI <<EOL
[security]
key = $KEY
port = $PORT
EOL
else
  KEY=$(awk -F " = " '/key/ {print $2}' $INI)
  PORT=$(awk -F " = " '/port/ {print $2}' $INI)
fi

cli_output "Authentication key : $KEY"


# Gather Sensors
display_sensors(){
  json_output=''
  # Read sensors on the specified sensor path
  sensors=`ls ${SENSORS_PATH} |grep \.inc`

  declare -A sensors_output
  for s in $sensors; do
    source ${SENSORS_PATH}/${s}
    # Put sensors according to their package in an array
    if [[ ${sensors_output[$sensor_package]} ]]; then
      sensors_output[$sensor_package]="${sensors_output[$sensor_package]},${sensor_output}"
    else
      sensors_output[$sensor_package]="${sensor_output}"
    fi
  done 

  # Expose all sensors output in a JSON
  for sensor_package in "${!sensors_output[@]}"
  do
    if [[ ! "$json_output" == "" ]]; then
      json_output="${json_output},"
    fi
    json_output=`printf '%s"%s":{%s}' "$json_output" "$sensor_package" "${sensors_output[$sensor_package]}"`
  done

  printf '{"system": {"daemon": "bashmonit/%s", "generation_date":"%s"}, "sensors": {%s}}' "$VERSION" "$(date)" "$json_output"
}


# Send the output as HTTP response
render_http_output(){
  cli_output "Response HTTP/${1} sent for $url"

  # Manual MIME/TYPE
  if [[ "$2" == "json" ]]; then
    content_type="application/json"
  else
    content_type="text/html"
  fi

  # HTTP/404 Error
  if [[ "$1" == "404" ]]; then
    error_msg="Unknown resource. This URL does not exist or is not supported."
    filedata=`printf '{"system":{"daemon": "bashmonit/%s", "generation_date":"%s", "error": 404, "error_long": "%s"}}\n' "$VERSION" "$(date)" "$error_msg"`
    TRES="HTTP/1.1 404 Not Found
Cache-Control: private
Server: bashmonit/$VERSION
Content-Type: ${content_type}
Connection: Close
Content-Length: ${#filedata}

$filedata"

  # HTTP/403 Error
  elif [[ "$1" == "403" ]]; then
    if [[ ! "$3" == "" ]]
      then
      filedata=$3
    else
      error_msg="Unauthorized access, you must specify a valid authentication key in get parameters."
      filedata=`printf '{"system":{"daemon": "bashmonit/%s", "generation_date":"%s", "error": 403, "error_long": "%s"}}\n' "$VERSION" "$(date)" "$error_msg"`
    fi
    TRES="HTTP/1.1 403 Forbidden
Cache-Control: private
Server: bashmonit/$VERSION
Content-Type: ${content_type}
Connection: Close
Content-Length: ${#filedata}

$filedata"

  # HTTP/200 Error
  else
    filedata=$3
    TRES="HTTP/1.1 200 OK
Cache-Control: private
Server: bashmonit/$VERSION
Content-Type: ${content_type}
Connection: Close
Content-Length: ${#filedata}

$filedata"
  fi

cat >$HTTP_RESPONSE <<EOF
$TRES
EOF
}


# Test if port is already used
TEST_PORT=`lsof -i:${PORT}`
if [[ ! "$TEST_PORT" == "" ]]; 
then
  APP_PORT=`lsof -i:${PORT} | awk 'NR==2 {print $1" (pid:"$2")"}'`

  cli_output "Port $PORT already in use, please free this port or configure another one."
  cli_output "The following app seems to use the port : $APP_PORT"
  cli_output "Exiting app"
  exit 0
fi

[ -p $HTTP_RESPONSE ] || mkfifo $HTTP_RESPONSE
cli_output "Server bashmonit/$VERSION (build $BUILD_DATE) started on port $PORT"

if $FIRST_RUN ; then
  cli_output "First run, you can get your data on http://127.0.0.1/?key=${KEY}"
fi

# Launch Webserver
while true ; do
  ( cat $HTTP_RESPONSE ) | nc -l -p $PORT | (
  REQ=`while read L && [ " " "<" "$L" ] ; do echo "$L" ; done`
  url="${REQ#GET }"
  url="${url% HTTP/*}"

  # Split get into arguments
  url=(${url//\?/ })

  # Retrieve Get Parameters and put them in an array
  declare -A getArguments
  params=${url[1]}
  params=(${params//\&/ })
  for param in ${params[@]}
  do
    param=(${param//\=/ })
    getArguments[${param[0]}]=${param[1]}
  done


  # Root URL redirected to sensors
  if [[ "${url[0]}" == "/" ]]; then
    # Requires a valid key
    if [ -z ${getArguments['key']} ] 
    then
        render_http_output 403 json ""
    else
      if [[ "${getArguments[key]}" == "${KEY}" ]] 
      then
        filedata="$(display_sensors)"
        render_http_output 200 json "${filedata}"
      else
        render_http_output 403 json ""
      fi
    fi
  else
    render_http_output 404 json ""
  fi
  )
done