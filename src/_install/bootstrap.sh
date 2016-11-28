#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='pho'

# Create project folder, written in 3 single mkdir-statements to make sure this runs everywhere without problems
sudo mkdir -p "/var/www/html/${PROJECTFOLDER}"

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get install -y apache2
sudo apt-get install -y php5

sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
sudo apt-get install php5-mysql

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/${PROJECTFOLDER}/src/public"
    <Directory "/var/www/html/${PROJECTFOLDER}/src/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
sudo a2enmod rewrite

# restart apache
service apache2 restart

# install curl (needed to use git afaik)
sudo apt-get -y install curl
sudo apt-get -y install php5-curl

# install openssl (needed to clone from GitHub, as github is https only)
sudo apt-get -y install openssl

# install PHP GD, the graphic lib (we create captchas and avatars)
sudo apt-get -y install php5-gd

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# go to project folder, load Composer packages
cd "/var/www/html/${PROJECTFOLDER}/src"
composer install

# run SQL statements from install folder
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/src/_install/01-create-database.sql"
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/src/_install/02-create-table-users.sql"
sudo mysql -h "localhost" -u "root" "-p${PASSWORD}" < "/var/www/html/${PROJECTFOLDER}/src/_install/03-create-table-notes.sql"

# writing rights to avatar folder
sudo chmod 0777 -R "/var/www/html/${PROJECTFOLDER}/src/public/avatars"

# remove Apache's default demo file
sudo rm "/var/www/html/index.html"

# final feedback
echo "Voila!"