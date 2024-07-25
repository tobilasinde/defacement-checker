#!/bin/bash
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

TDC_DIR=/usr/lib/tdc
SITE_DIR=$1
while [ -z $SITE_DIR ] || [ ! -d $SITE_DIR ]
do
    read -p "Enter site directory [ /var/www/.../your_app ]: " SITE_DIR
done
node $TDC_DIR/generate.js $SITE_DIR $TDC_DIR
