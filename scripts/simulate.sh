#!/bin/bash

PLAY="/usr/bin/python /opt/victronenergy/dbus-recorder/play.py"
DBUS="/usr/bin/dbus"
RUN_DIR="/root"
SIMULATIONS="$RUN_DIR/simulations"

help() {
	echo "Usage: $0 simulation_name"
	echo
	echo "Available simulations:"
	for d in $SIMULATIONS/*; do
		echo -n `basename $d`": "
		cat $SIMULATIONS/`basename $d`/description
	done
}

settings_available() {
        python -c 'import sys, dbus; sys.exit("com.victronenergy.settings" not in dbus.SystemBus().list_names())'
}

if test -z "$1"; then
	help
	exit 0
fi

sim=${1,,}

# First restore the default config
svc -d /service/localsettings
cp /data/conf/settings.xml.orig /data/conf/settings.xml
svc -u /service/localsettings
svc -t /service/dbus-systemcalc-py

# Wait for localsettings
echo -n "Waiting for localsettings "
while ! settings_available; do
        echo -n '.'
        sleep 1
done; echo

# Perform any setup that might be required for this demo
echo "Applying settings for this simulation..."
if test -f $SIMULATIONS/$sim/setup; then
	while read -r line; do
		read -r service path value <<< "$line"
		$DBUS -y $service $path SetValue "$value" > /dev/null
	done < $SIMULATIONS/$sim/setup
fi

echo "Starting the simulation, press ctrl+C to terminate."
if test "$sim" = "z"; then
  /opt/victronenergy/dbus-recorder/play.sh 3 &
else
  $PLAY $SIMULATIONS/$sim/*.dat
fi
