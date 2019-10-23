#!/bin/bash
apt update
#Install needed software
apt install  -y php7.1 php-xml php-mbstring php-bcmath php-curl php-mysql php-tokenizer openssl
apt install  -y mysql-server nginx

#Wait for Mysql to be available
while !(mysqladmin ping)
do
    sleep 3
    echo "waiting for mysql ..."
done

#Remove all default config and web files
rm /etc/nginx/sites-enabled/* && rm /etc/nginx/sites-available/*
rm /var/www/html/*

#Create index file for website
cat <<EOF >> /var/www/html/index.php
<?php
echo 'Hello World';
?>
EOF

#Create new config for web server
cat <<EOF >> /etc/nginx/sites-enabled/default.conf
server {
    listen 80;
    root /var/www/html;

    location / {
        index index.php;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.1-fpm.sock;
    }
}
EOF

#Restart nginx and php-fpm service for changes to take effect
systemctl restart nginx
systecmctl restart php7.1-fpm