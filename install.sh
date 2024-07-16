#!/bin/bash
set -eu -o pipefail
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi
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
if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
fi
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
| tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
| tee /etc/apt/sources.list.d/nginx.list
apt update
apt-get install -y nginx-module-njs

nginx_path=/etc/nginx
while [ ! -f $nginx_path/nginx.conf  ]
do
    read -p "Enter correct path for nginx.conf [ ie. /etc/nginx ]: " nginx_path
done
njs_path=$nginx_path/njs/
if ! grep -Fq "load_module modules/ngx_http_js_module.so;" $nginx_path/nginx.conf
then
    echo -e "load_module modules/ngx_http_js_module.so;\n$(cat $nginx_path/nginx.conf)" > $nginx_path/nginx.conf
fi
if ! grep -Fq "js_import main from njs/verify.js;" $nginx_path/nginx.conf
then
    sed -i -e '/http {/a js_import main from njs/verify.js;'$'\n' $nginx_path/nginx.conf
fi
if [ -d "$njs_path" ]; then
    cp ./verify.js $njs_path
    cp ./generate.js $njs_path
else
    mkdir $njs_path
    cp ./verify.js $njs_path
    cp ./generate.js $njs_path
fi
if [ ! -d "$njs_path/hashes" ]; then
    mkdir $njs_path/hashes
fi
sed -i "s|.*installation_path=.*|installation_path=$njs_path|" tony_njs.sh
chmod +x tony_njs.sh
cp ./tony_njs.sh /usr/bin/tony_njs