#!/bin/bash
# install.sh -- Installer
# chmod 755 install.sh
# then run: ./install.sh
#
# Bashmonit Installer
#
# The MIT License (MIT)
# Copyright (c) 2017 Charles Bourgeaux <charles@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

APP_DIR=$(dirname "$0")
REQUIRED_PACKAGES=( "nc" "awk" "netstat" "sensors" "bc" "jq" "netcat" "gawk" "lsblk" "smartctl")

# Requires ROOT for NC
if [[ `id -u` -ne 0 ]]; then
  echo "This installer needs ROOT privileges. Please log as root or use sudo."
  exit 0
fi


# Manage arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -h|--help)
    shift # past argument
    printf "Bashmonit Installer\n"
    printf "(c) Charles Bourgeaux <charles@resmush.it>\n"
    printf "Usage: ./install.sh [--yes]\n"
    printf "Startup:\n"
    printf "  -h or --help \t\t print this help.\n"
    printf "  -y or --yes \t\t to disable prompt.\n"
    printf "  --no-first-run \t to disable first run after install.\n"
    exit 0
  ;;
  -y|--yes)
    AGREE=y
    shift # past argument
  ;;
  --no-first-run)
    DISABLE_FIRST_RUN=y
    shift # past argument
  ;;
  *)    # unknown option
    shift # past argument
  ;;
esac
done

while [[ "$AGREE" != "y" ]] && [[ "$AGREE" != "n" ]] 
do
read -p "This script will install bashmonit on your system (Y/n) : " AGREE
done

if [ "$AGREE" = "y" ] ;
then
  # Check required packages and try to install them
  for x in ${REQUIRED_PACKAGES[@]}
  do
  if ! which $x > /dev/null; then
    echo "Some packages are required to execute bashmonit. $x"
    echo -e "Try to install it ? (Y/n) \c"
    if [[ "$x" == "sensors" ]]
      then
      x="lm-sensors"
    fi
    if [[ "$x" == "smartctl" ]]
      then
      x="smartmontools"
    fi
    read
    if [[  ! "$REPLY" == "n" ]]; then
       if ! which sudo > /dev/null || ! which apt-get > /dev/null; then
        echo "Cannot install package '$x' automatically. Please install it manually."
        exit 0
      else
        echo "Installing package ${x}..."
        sudo apt-get -qq update
        sudo apt-get -y -qq install $x 
      fi
    else
      echo "Some package are missing. Try to install them before."
      exit 0
    fi
  fi
  done

  echo "Installing app..."
  cp $APP_DIR/bashmonit.sh /usr/local/sbin/bashmonit
  chmod +x /usr/local/sbin/bashmonit
  mkdir -p /etc/bashmonit.d
  rm -rf /etc/bashmonit.d/*.inc
  cp $APP_DIR/sensors/* /etc/bashmonit.d/ -R
  
  # Create log rotate entry if not exist
  if [ ! -f '/etc/logrotate.d/bashmonit' ]; then
    cat > /etc/logrotate.d/bashmonit <<EOL
/var/log/bashmonit.log {
        rotate 10
        compress
        notifempty
        missingok
        weekly
        delaycompress
}
EOL
  fi

  if ! which bashmonit > /dev/null; then
    echo "Something failed in your bashmonit installation Command 'bashmonit' not accessible."
    exit 0
  else
    echo "Bashmonit has been correctly installed."
    APP_VER=`bashmonit -v`
    echo "Version installed : $APP_VER"
  fi
  if [[ $DISABLE_FIRST_RUN != "y" ]]; then
    echo "First run forced !"
    /usr/local/sbin/bashmonit
  fi
else
  echo "Bashmonit hasn't been installed."
  exit 0
fi



