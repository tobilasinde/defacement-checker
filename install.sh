#!/bin/bash
set -eu
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi
WEBSERVER=""
if [ $# -ge 1 ] && [ -n "$1" ]; then
    WEBSERVER=$1
fi
while [ -z $WEBSERVER ] || [ ! $WEBSERVER = "nginx" -a ! $WEBSERVER = "apache" ]
do
    read -p "Webserver[ nginx/apache ]: " WEBSERVER
done
TDC_DIR=/usr/lib/tdc
sed -i "s|.*TDC_DIR=.*|TDC_DIR=$TDC_DIR|" tdc.sh
sed -i "s|.*TDC_DIR=.*|TDC_DIR=$TDC_DIR|" ./tdc/functions.js
sed -i "s|.*TDC_DIR=.*|TDC_DIR=$TDC_DIR|" ./tdc/verify.js
if [ ! -d "$TDC_DIR" ]; then
    mkdir $TDC_DIR
fi
if [ ! -d "$TDC_DIR/hashes" ]; then
    mkdir $TDC_DIR/hashes
fi
cp -r ./tdc/* $TDC_DIR
chmod +x tdc.sh
cp ./tdc.sh /usr/bin/tdc

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
    if ! grep -Fq "load_module modules/ngx_http_js_module.so;" $NGINX_DIR
    then
        echo -e "load_module modules/ngx_http_js_module.so;\n$(cat $NGINX_DIR)" > $NGINX_DIR
    fi
    if ! grep -Fq "js_import main from verify.js;" $NGINX_DIR
    then
        sed -i '/http {/a\   js_import main from verify.js;' $NGINX_DIR
    fi
    if ! grep -Fq "js_path $TDC_DIR/;" $NGINX_DIR
    then
        sed -i "/http {/a\   js_path $TDC_DIR/;" $NGINX_DIR
    fi
    systemctl restart nginx
    echo "----- Installation completed -----"
    echo 'run "tdc generate /path/to/your/site" to generate hashes'
    # echo 'run "tdc check /path/to/your/app" to check for defacement'
    echo 'add the following line to each location block of your site server block'
    echo 'js_header_filter main.header;'
    echo 'js_body_filter main.verify;'
    echo 'run "systemctl restart nginx" to apply changes'
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
    sed -i "s|.*char \*tdc_dir =.*|        char *tdc_dir = \"$TDC_DIR/functions.js\";|" ./apache/mod_tdc.c
    apxs -i -a -c ./apache/mod_tdc.c
    systemctl restart apache2
fi