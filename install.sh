#!/bin/bash
set -eu
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Permission denied"
    exit
fi
WEBSERVER=""
ADMIN_EMAIL=""
if [ $# -ge 1 ] && [ -n "$1" ]; then
   WEBSERVER=$1
fi
while [ -z $WEBSERVER ] || [ ! $WEBSERVER = "nginx" -a ! $WEBSERVER = "apache" ]
do
    read -p "Webserver[ nginx/apache ]: " WEBSERVER
done
while [ -z $ADMIN_EMAIL ]
do
    read -p "Enter the server admin email: " ADMIN_EMAIL
done
WDD_DIR=/usr/lib/wdd
sed -i "s|.*WDD_DIR=.*|WDD_DIR=$WDD_DIR|" wdd.sh
sed -i "s|.*WDD_DIR=.*|WDD_DIR=$WDD_DIR|" ./wdd/verificationService.mjs
sed -i "s|.*const email = .*|const email = '$ADMIN_EMAIL'|" ./wdd/notification.js
if [ ! -d "$WDD_DIR" ]; then
    mkdir $WDD_DIR
fi
if [ ! -d "$WDD_DIR/hashes" ]; then
    mkdir $WDD_DIR/hashes
fi
cp -r ./wdd/* $WDD_DIR
chmod +x wdd.sh
cp ./wdd.sh /usr/bin/wdd

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
    if ! grep -Fq "js_import main from njs.js;" $NGINX_DIR
    then
        sed -i '/http {/a\   js_import main from njs.js;' $NGINX_DIR
    fi
    if ! grep -Fq "js_path $WDD_DIR/;" $NGINX_DIR
    then
        sed -i "/http {/a\   js_path $WDD_DIR/;" $NGINX_DIR
    fi
    systemctl restart nginx
    echo "----- Installation completed -----"
    echo 'run "wdd generate /path/to/your/site" to generate hashes'
    # echo 'run "wdd check /path/to/your/app" to check for defacement'
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
    sed -i "s|.*char \*wdd_dir =.*|        char *wdd_dir = \"$WDD_DIR/apache.mjs\";|" ./apache/mod_wdd.c
    apxs -i -a -c ./apache/mod_wdd.c
    systemctl restart apache2
fi
