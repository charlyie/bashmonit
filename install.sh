#!/bin/bash
# install.sh -- Installer
# chmod 755 install.sh
# then run: ./install.sh
#
# Bashmonit Installer
#
# The MIT License (MIT)
# Copyright (c) 2017 Charles Bourgeaux <contact@resmush.it> and contributors
# You are not obligated to bundle the LICENSE file with your projects as long
# as you leave these references intact in the header comments of your source files.

APP_DIR=$(dirname "$0")
REQUIRED_PACKAGES=( "nc" "awk" "netstat" "sensors" "bc" "jq")

# Requires ROOT for NC
if [[ `id -u` -ne 0 ]]; then
  echo "This installer needs ROOT privileges. Please log as root or use sudo."
  exit 0
fi

read -p "This script will install bashmonit on your system (Y/n) : " AGREE

if [ ! "$AGREE" = "n" ] ;
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
  cp $APP_DIR/sensors/* /etc/bashmonit.d/ -R
  #cp $APP_DIR/bashmonitd.sh /etc/init.d/bashmonit
  #chmod +x /etc/init.d/bashmonit
  #systemctl daemon-reload
  
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
    echo "First run forced !"
  fi

  /usr/local/sbin/bashmonit
else
  echo "Bashmonit hasn't been installed."
  exit 0
fi



