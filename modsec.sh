#!/bin/bash
apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev nginx
mkdir build
cd build
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install
cd ..
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
NGINX_VERSION=$(nginx -v 2>&1 | awk -F'/' '{print $2}' | awk '{print $1}')
wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar zxvf nginx-$NGINX_VERSION.tar.gz
cd nginx-$NGINX_VERSION
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules
mkdir /etc/nginx/modules
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
sed -i '1i\load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf
mkdir /etc/nginx/modsec
wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
cd ..
cp ModSecurity/unicode.mapping /etc/nginx/modsec
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
sed -i '0,/server {/s/server {/&\n    modsecurity on;\n    modsecurity_rules_file \/etc\/nginx\/modsec\/main.conf;/' /etc/nginx/sites-enabled/default
wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v3.3.5.tar.gz
tar -xzvf v3.3.5.tar.gz
mv coreruleset-3.3.5/ /usr/local/
cd /usr/local/coreruleset-3.3.5/
sudo cp crs-setup.conf.example crs-setup.conf
touch /etc/nginx/modsec/main.conf
printf 'Include "/etc/nginx/modsec/modsecurity.conf"\nInclude "/usr/local/coreruleset-3.3.5/crs-setup.conf" \nInclude "/usr/local/coreruleset-3.3.5/rules/*.conf"\n' >> /etc/nginx/modsec/main.conf


