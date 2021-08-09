#!/bin/bash
# bashmonit.sh -- http://127.0.0.1:8765/?key=XXXX
# chmod 755 bashmonit.sh
# then run: ./bashmonit.sh
#
# Based on bashttp : webserver in bash
#
# The MIT License (MIT)
# Copyright (c) 2017-2021 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.


PORT=8765
VERSION="1.2.9"
BUILD_DATE="20210809"
REQUIRED_PACKAGES=( "nc" "awk" "netstat" "bc" "jq")

HTTP_RESPONSE=/tmp/webresp
APP_DIR=$(dirname "$0")
SENSORS_PATH=/etc/bashmonit.d
LOG="/var/log/bashmonit.log"
INI="/etc/bashmonit.conf"
FIRST_RUN=false
QUIET=false
UPDATE_LOCKFILE="/tmp/.bashmonit.update"

# Display output and save it to log file.
cli_output(){
  TIME="[`date '+%Y-%m-%d %H:%M:%S'`] "
  if [[ $2 == "notime" ]]; then
    TIME=""
  fi
  if $QUIET ; then
    printf "${TIME}$1\n" > ${LOG}
  else
    #printf "${TIME}$1\n" | tee -a ${LOG}
    printf "${TIME}$1\n"
  fi
}

check_update(){
  _SCRIPT_NAME=`basename "$0" | cut -f 1 -d '.'`

  # Perform update verification once a day
  if [ -f ${UPDATE_LOCKFILE} ]; then
    _UPDATE_LOCKFILE_VALUE=`cat $UPDATE_LOCKFILE`

    if [[ $_UPDATE_LOCKFILE_VALUE == "false" ]]; then
      if [[ $(find "${UPDATE_LOCKFILE}" -mtime -1 -print) ]]; then
        return
      fi
    else
      cli_output "An update is available. Run \`${_SCRIPT_NAME} --update\` to perform an upgrade"
      return
    fi
    
  fi
  cli_output "Checking for update..."
  _REQUEST_OUTPUT=`curl --silent "https://api.github.com/repos/charlyie/bashmonit/tags"`
  _REMOTE_VERSION=`echo ${_REQUEST_OUTPUT} | jq -r '.[0].name'`
  _TARBALL=`echo ${_REQUEST_OUTPUT} | jq -r '.[0].tarball_url'`

  if [[ $_REMOTE_VERSION == "${VERSION}" ]]; then
    cli_output "No update required (remote version is : ${_REMOTE_VERSION})"
    if [ -f "${UPDATE_LOCKFILE}" ]; then
      if [ -w $UPDATE_LOCKFILE ]; then
        echo "false" > $UPDATE_LOCKFILE
      else
        cli_output "Cannot write temporary file $UPDATE_LOCKFILE, please check if this file is writeable"
      fi
    else
      echo "false" > $UPDATE_LOCKFILE
    fi
  else
    _INSTALL_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    _SCRIPT_PATH=`echo ${_INSTALL_DIR}/${_SCRIPT_NAME}`

    cli_output "An update is available (${_REMOTE_VERSION}). Run \`${_SCRIPT_NAME} --update\` to perform an upgrade"
    if [ -f "${UPDATE_LOCKFILE}" ]; then
      if [ -w $UPDATE_LOCKFILE ]; then
        echo "true" > $UPDATE_LOCKFILE
      else
        cli_output "Cannot write temporary file $UPDATE_LOCKFILE, please check if this file is writeable"
      fi
    else
      echo "true" > $UPDATE_LOCKFILE
    fi
  fi
}

do_update(){
  _REQUEST_OUTPUT=`curl --silent "https://api.github.com/repos/charlyie/bashmonit/tags"`
  _REMOTE_VERSION=`echo ${_REQUEST_OUTPUT} | jq -r '.[0].name'`
  _TARBALL=`echo ${_REQUEST_OUTPUT} | jq -r '.[0].tarball_url'`

  if [[ $_REQUEST_OUTPUT == "${VERSION}" ]]; then
    cli_output "No update required (remote version is : ${_REMOTE_VERSION})"
  else
    _INSTALL_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    _SCRIPT_NAME=`basename "$0"`
    _SCRIPT_PATH=`echo ${_INSTALL_DIR}/${_SCRIPT_NAME}`

    cli_output "> Local version  : ${VERSION}"
    cli_output "> Remote version : ${_REMOTE_VERSION}"

    if [[ "${VERSION}" !=  "${_REMOTE_VERSION}" ]]; then
      cli_output "An update is available (${_REMOTE_VERSION}). Launching upgrade..."

      cli_output "> Downloading from ${_TARBALL}..."
      if [ -d "/tmp/bashmonit-last-release" ]; then
        rm -rf /tmp/bashmonit-last-release
      fi
      mkdir -p /tmp/bashmonit-last-release
      curl -L ${_TARBALL} --output /tmp/bashmonit-last-release.tar.gz --silent
      cli_output "> Extracting tarball..."
      tar xf /tmp/bashmonit-last-release.tar.gz -C /tmp/bashmonit-last-release
      cli_output "> Executing install..."
      chmod +x /tmp/bashmonit-last-release/*/install.sh
      /tmp/bashmonit-last-release/*/install.sh --yes --no-first-run
      rm -f $UPDATE_LOCKFILE
      exit 0
    else
      cli_output "No update available"
    fi
  fi
}

# Manage arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -q|--quiet)
    QUIET=true
    shift # past argument
    ;;
    --update)
    shift # past argument
    do_update
    exit 0
    ;;
    -h|--help)
    shift # past argument
    cli_output "Bashmonit v.${VERSION}, server Monitoring tool, extensible with custom sensors, and outputing a JSON on a standalone HTTP server" notime
    cli_output "(c) Charles Bourgeaux <charles@resmush.it>" notime
    cli_output "Usage: bashmonit [--quiet] [--update]" notime
    cli_output "Startup:" notime
    cli_output "  -h or --help \t\t print this help." notime
    cli_output "  -v or --version \t display the version of Bashmonit" notime
    cli_output "  --quiet \t\t avoid output display." notime
    cli_output "  --update \t\t perform an upgrade of this app.\n" notime
    cli_output "  --get-key \t\t returns security token.\n" notime
    cli_output "  --get-port \t\t returns app port.\n" notime
    cli_output "Logs:" notime
    cli_output "  Output \t\t /var/log/bashmonit.log\n" notime
    cli_output "Configuration:" notime
    cli_output "  General \t\t /etc/bashmonit.conf" notime
    cli_output "  Sensors \t\t /etc/bashmonit.d/*\n" notime
    exit 0
    ;;
    -v|--version)
    shift # past argument
    cli_output "Bashmonit v.${VERSION} (build ${BUILD_DATE})" notime
    exit 0
    ;;
    --get-key)
    shift # past argument
    if [ ! -f "$INI" ]; then
      cli_output "No configuration file created yet. Please launch app at least one time."
    else
      KEY=$(awk -F " = " '/key/ {print $2}' $INI)
      cli_output "Authentication key : $KEY" notime
    fi
    exit 0
    ;;
    --get-port)
    shift # past argument
    if [ ! -f "$INI" ]; then
      cli_output "No configuration file created yet. Please launch app at least one time."
    else
      PORT=$(awk -F " = " '/port/ {print $2}' $INI)
      cli_output "Port : $PORT" notime
    fi
    exit 0
    ;;
    -*)    # unknown option
    cli_output "Invalid option: ${1}. Type --help to show help" notime
    shift
    exit 0
    ;;
    --*)    # unknown option
    cli_output "Invalid option: ${1}. Type --help to show help" notime
    shift 
    exit 0
    ;;
    *)    # unknown option
    shift # past argument
    ;;
esac
done



cli_output "Starting daemon bashmonit..."
# Requires ROOT for NC
if [[ `id -u` -ne 0 ]]; then
  cli_output "This daemon needs ROOT privileges. Please log as root or use sudo."
  exit 0
fi

check_update


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
  cli_output "First run, you can get your data on http://127.0.0.1:${PORT}/?key=${KEY}"
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