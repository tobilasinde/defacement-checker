#!/bin/bash
# set -eu -o pipefail
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

installation_path=/etc/nginx/njs
url=$1
path=$2
while [ -z $url ]
do
    read -p "Enter url [ unique_app_name/url ]: " url
done
while [ -z $path ] || [ ! -d $path ]
do
    read -p "Enter path to site files [ /var/www/.../your_app ]: " path
done
node $installation_path/generate.js $url $path $installation_path
