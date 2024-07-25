#!/bin/bash
set -eu
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi
WEBSERVER=""
if [ $# -ge 1 ] && [ -n "$1"]; then
    WEBSERVER=$1
fi
while [ -z $WEBSERVER ] || [ ! $WEBSERVER = "nginx" -a ! $WEBSERVER = "apache" ]
do
    read -p "Webserver[ nginx/apache ]: " WEBSERVER
done
echo "Checking node.js installation"
if ! command -v node &> /dev/null; then
    if ! command -v curl &> /dev/null; then
        apt-get install -y curl
    fi
    echo "Node.js not found, installing..."
    curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    apt-get install -y nodejs
    echo "Node.js installed"
fi
TDC_DIR=/usr/lib/tdc
if [ $WEBSERVER = "nginx" ]; then
    echo "Checking nginx installation"
    if ! command -v nginx &> /dev/null; then
        apt-get install -y nginx
    fi
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
    apt update
    apt-get install -y nginx-module-njs-dbg
    # nginx-module-njs
    NGINX_DIR=$(nginx -V 2>&1 | grep -o '\-\-conf-path=\(.*conf\)' | cut -d '=' -f2)
    sed -i "s|.*TDC_DIR=.*|TDC_DIR=$TDC_DIR|" tdc.sh
    sed -i "s|.*TDC_DIR=.*|TDC_DIR=$TDC_DIR|" ./tdc/functions.js
    if ! grep -Fq "load_module modules/ngx_http_js_module.so;" $NGINX_DIR
    then
        echo -e "load_module modules/ngx_http_js_module.so;\n$(cat $NGINX_DIR)" > $NGINX_DIR
    fi
    if ! grep -Fq "js_import main from verify.js;" $NGINX_DIR
    then
        sed -i -e '/http {/a js_import main from verify.js;'$'\n' $NGINX_DIR
    fi
    if ! grep -Fq "js_path $TDC_DIR;" $NGINX_DIR
    then
        sed -i -e '/http {/a js_path $TDC_DIR;'$'\n' $NGINX_DIR
    fi
fi
if [ $WEBSERVER = "apache" ]; then
    echo "Checking apache installation"
    if ! command -v apache2 &> /dev/null; then
        apt-get install -y apache2 
    fi
    if ! command -v apache2-dev &> /dev/null; then
        apt-get install -y apache2-dev 
    fi
    APACHE_DIR=$(apache2 -V 2>&1 | grep -o '\-D HTTPD_ROOT=\(.*\)' | cut -d '=' -f2)/$(apache2 -V 2>&1 | grep -o '\-D SERVER_CONFIG_FILE=\(.*conf\)' | cut -d '=' -f2)
    sed -i "s|.*char *tdc_dir =.*|char *tdc_dir = $TDC_DIR|" tdc.sh
    sed -i "s|.*const TDC_DIR =.*|const TDC_DIR = $TDC_DIR|" ./tdc/functions.js
    apxs -i -a -c ./apache/mod_tdc.c
fi

if [ ! -d "$TDC_DIR" ]; then
    mkdir $TDC_DIR
fi
if [ ! -d "$TDC_DIR/hashes" ]; then
    mkdir $TDC_DIR/hashes
fi
cp -r ./tdc/* $TDC_DIR
chmod +x tdc.sh
cp ./tdc.sh /usr/bin/tdc