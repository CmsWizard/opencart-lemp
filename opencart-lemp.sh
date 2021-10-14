#! /bin/bash

echo "==============================================================="
echo "=========== Welcome to the Opencart CMS installer ============="
echo "==============================================================="
echo -n "Enter your domain name > "
read var01
echo -n "Enter your email address > "
read var02

var011=`echo "$var01" | sudo sed "s/www.//g"`
varnaked=`echo "$var01" | grep -q -E '(.+\.)+.+\..+$' || echo "true" && echo "false"`
varwww=`echo "$var01" | grep -q "www." && echo "true" || echo "false"`


echo ""

if $varnaked;
  then echo "Make sure '$var01' & 'www.$var01' both point towards your server IP address, else installation will fail";
elif $varwww;
  then echo "Make sure '$var011' & '$var01' both point towards your server IP address, else installation will fail";
else 
  echo "Make sure '$var01' point towards your server IP address, else installation will fail";
fi

echo ""


echo -n "Press 'y' to continue > "
read varinput
echo "Yy" | grep -q "$varinput" && echo "continuing..." || echo "exiting..."
echo "Yy" | grep -q "$varinput" || exit 1


echo "================================================================"
echo "======== A robot is now installing Opencart CMS for you ======="
echo "========================== ETC = 120s =========================="
echo "================================================================"

# initial setup
sudo apt-get update
sudo apt-get install pwgen -y
sudo apt-get install gpw -y
sudo apt-get install nano -y
sudo apt-get install software-properties-common -y
sudo apt-get install mariadb-server mariadb-client -y
sudo apt-get install certbot -y
sudo apt-get install cron -y
sudo apt-get install zip -y
sudo apt-get install unzip -y

sudo apt disable ufw -y
sudo apt remove iptables -y
sudo apt purge iptables -y


# random string generation
var03=$(gpw 1 8)
var04=$(gpw 1 8)
var05=$(pwgen -s 16 1)
var06=$(pwgen -s 16 1)


# STEP1 configuring PHP
echo | sudo add-apt-repository ppa:ondrej/php
echo | sudo add-apt-repository ppa:ondrej/nginx
sudo apt-get update
sudo apt install php7.4-fpm php7.4-common php7.4-mysql php7.4-gmp php7.4-curl php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-gd php7.4-xml php7.4-soap php7.4-cli php7.4-zip php7.4-soap -y
sudo apt-get install php-imagick -y
sudo apt-get install php7.4-imagick -y
sudo bash -c 'echo short_open_tag = On >> /etc/php/7.4/fpm/php.ini'
sudo bash -c 'echo cgi.fix_pathinfo = 0 >> /etc/php/7.4/fpm/php.ini'
sudo bash -c 'echo date.timezone = America/Chicago >> /etc/php/7.4/fpm/php.ini'
sudo sed -i "s/max_execution_time = 30/max_execution_time = 600/g" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 64M/g" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 64M/g" /etc/php/7.4/fpm/php.ini


# STEP2 configuring DATABASE
sudo mysql -u root -e "CREATE DATABASE $var03;"
sudo mysql -u root -e "CREATE USER '$var04'@'localhost' IDENTIFIED BY '$var05';"
sudo mysql -u root -e "GRANT ALL ON $var03.* TO '$var04'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
sudo mysqladmin password "$var06"
sudo mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -u root -e "DROP DATABASE IF EXISTS test;"
sudo mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"


# STEP3 configuring SSL

sudo systemctl stop nginx.service
sudo systemctl stop apache.service
sudo systemctl stop apache2.service

if $varnaked;
  then yes | sudo certbot certonly --non-interactive --standalone --preferred-challenges http --email "$var02" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "$var01" -d www."$var01";
elif $varwww;
  then yes | sudo certbot certonly --non-interactive --standalone --preferred-challenges http --email "$var02" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "$var01" -d "$var011";
else 
  yes | sudo certbot certonly --non-interactive --standalone --preferred-challenges http --email "$var02" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "$var01";
fi


# STEP4 configuring NGINX
sudo apt-get install nginx -y
sudo systemctl restart nginx.service

if $varnaked;
  then sudo wget --no-check-certificate 'https://raw.githubusercontent.com/cmswizard/opencart-lemp/main/config.txt' -O /etc/nginx/sites-enabled/"$var01" && sudo sed -i "s/domain/$var01/g" /etc/nginx/sites-enabled/"$var01";
elif $varwww;
  then sudo wget --no-check-certificate 'https://raw.githubusercontent.com/cmswizard/opencart-lemp/main/config-www.txt' -O /etc/nginx/sites-enabled/"$var01" && sudo sed -i "s/domain/$var011/g" /etc/nginx/sites-enabled/"$var01";
else 
  sudo wget --no-check-certificate 'https://raw.githubusercontent.com/cmswizard/opencart-lemp/main/config-non-www.txt' -O /etc/nginx/sites-enabled/"$var01" && sudo sed -i "s/domain/$var01/g" /etc/nginx/sites-enabled/"$var01";
fi

# optional packages update
# sudo apt-get update
#sudo apt-get upgrade -y
#sudo apt-get dist-upgrade -y
#sudo apt-get clean -y
#sudo apt-get autoclean -y
#sudo apt autoremove -y


# installing the app
sudo mkdir /var/www/"$var01"
cd /var/www/"$var01"
wget https://github.com/opencart/opencart/releases/download/3.0.3.8/opencart-3.0.3.8.zip -O latest.zip
unzip latest.zip
sudo rm latest.zip
#unzip -d "$var01" -j latest.zip
cd
sudo mv /var/www/"$var01"/upload/config-dist.php /var/www/"$var01"/upload/config.php
sudo mv /var/www/"$var01"/upload/admin/config-dist.php /var/www/"$var01"/upload/admin/config.php

sudo chown -R www-data:www-data /var/www/"$var01"
sudo chmod -R 0755 /var/www/"$var01"
sudo chown -R www-data:www-data /var/www/"$var01"/upload
sudo chmod -R 0755 /var/www/"$var01"/upload



# Removing obsolete files
# ###


# Restrating services
sudo systemctl restart nginx.service
sudo systemctl restart mysql.service
sudo systemctl restart php7.4-fpm

echo "========== please save this info in a secure place =========="
echo "your mysql username: root"
echo "your mysql password: $var06"
echo "your database name: $var03"
echo "your database username: $var04"
echo "your database password: $var05"

echo "=======================-== DONE! ============================"
echo "=========== Opencart CMS is installed sucessfully ==========="
echo "=================== =================== ====================="
