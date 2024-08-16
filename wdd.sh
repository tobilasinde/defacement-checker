#!/bin/bash
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Permission denied"
    exit
fi

WDD_DIR=/usr/lib/wdd
COMMAND=$1
SITE_DIR=$2
CHECKSUM=""
while [ -z $COMMAND ] || [ ! $COMMAND = "initialise" -a ! $COMMAND = "verify" -a ! $COMMAND = "schedule" ]
do
    read -p "Enter prompt [ initialise | verify | schedule ]: " COMMAND
done
while [ -z $SITE_DIR ] || [ ! -d $SITE_DIR ]
do
    read -p "Enter site directory [ /var/www/.../your_app ]: " SITE_DIR
done
if [ $COMMAND = "initialise" ]; then
    node $WDD_DIR/generate.mjs $SITE_DIR $WDD_DIR
fi
if [ $COMMAND = "verify" ]; then
    while [ -z $CHECKSUM ]
    do
        read -p "Enter the previous checksum of the website sent to you: " CHECKSUM
    done
    node $WDD_DIR/verify.mjs $WDD_DIR $SITE_DIR $CHECKSUM
fi

if [ $COMMAND = "schedule" ]; then
    while [ -z $UNIT ] || [ ! $UNIT = "minute" -a ! $UNIT = "hour" -a ! $UNIT = "day" -a ! $UNIT = "month" ]
    do
        read -p "Enter unit [minute, hour, day, month]: " UNIT
    done
    while [[ ! "$INTERVAL" =~ ^[0-9]+$ ]]
    do
        read -p "Enter interval (must be a number i.e 1): " INTERVAL
    done
    crontime="0 0 * * *"
    if [ $UNIT = "minute" ]; then
        crontime="*/$INTERVAL * * * *"
    elif [ $UNIT = "hour" ]; then
        crontime="0 */$INTERVAL * * *"
    elif [ $UNIT = "day" ]; then
        crontime="0 0 */$INTERVAL * *"
    elif [ $UNIT = "month" ]; then
        crontime="0 0 * */$INTERVAL *"
    fi
    croncmd="node $WDD_DIR/verify.mjs $WDD_DIR $SITE_DIR"
    cronjob="$crontime $croncmd"
    ( crontab -l | grep -v "$croncmd" ; echo "$cronjob" ) | crontab -
    echo "Verification schedule created for $SITE_DIR every $INTERVAL $UNIT (s)"
fi