#!/bin/bash

# Log all errors and warnings
exec > >(tee -a /var/log/script.log) 2>&1

# A function for pretty output
function print_message {
    COLOR=$1
    MESSAGE=$2
    case $COLOR in
        "red")    echo -e "\e[91m${MESSAGE}\e[0m" ;;
        "green")  echo -e "\e[92m${MESSAGE}\e[0m" ;;
        "yellow") echo -e "\e[93m${MESSAGE}\e[0m" ;;
        *)        echo -e "${MESSAGE}" ;;
    esac
}

# Check root Access
if [ "$EUID" -ne 0 ]; then
    print_message "red" "Please run script with ROOT access."
    exit 1
fi

# Update packages
print_message "yellow" "apt packages updating..."
sudo apt update -y
if [ $? -ne 0 ]; then
    print_message "red" "Failed update packages."
    exit 1
fi

# Install Nginx
print_message "yellow" "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx
    if [ $? -ne 0 ]; then
        print_message "red" "Error in install or running Nginx."
        exit 1
    fi
else
    print_message "green" "Nginx installed before."
fi

# Install php and modules
print_message "yellow" "Installing php modules..."
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y
sudo apt install php8.2 php8.2-fpm php8.2-cli php8.2-dev php8.2-pgsql php8.2-sqlite3 php8.2-gd php8.2-imagick \
  php8.2-curl php8.2-imap php8.2-mysql php8.2-mbstring php8.2-xml php8.2-zip \
  php8.2-bcmath php8.2-soap php8.2-intl php8.2-readline php8.2-ldap php8.2-msgpack \
  php8.2-igbinary php8.2-redis php8.2-memcache php8.2-pcov php8.2-xdebug -y
if [ $? -ne 0 ]; then
    print_message "red" "Error in install php modules."
    exit 1
fi

# PHP-FPM
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
if grep -q "^;cgi.fix_pathinfo=1" /etc/php/${PHP_VERSION}/fpm/php.ini; then
    sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/${PHP_VERSION}/fpm/php.ini
fi
sudo systemctl restart php${PHP_VERSION}-fpm
sudo systemctl enable php${PHP_VERSION}-fpm

# Install MySQL
print_message "yellow" "Installing MySQL..."
if ! command -v mysql &> /dev/null; then
    sudo apt install mysql-server -y
    sudo systemctl enable mysql
    sudo systemctl start mysql
    if [ $? -ne 0 ]; then
        print_message "red" "Erro in install or running MySQL."
        exit 1
    fi
    # Set password for root user. please use another user . root is so danger
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your-password';"
    sudo mysql -e "FLUSH PRIVILEGES;"
else
    print_message "green" "MySQL installed before."
fi

# Create sample project directory
PROJECT_ROOT="/var/www/myproject"
print_message "yellow" "Project directory creating ${PROJECT_ROOT}..."
sudo mkdir -p $PROJECT_ROOT
sudo chown -R $USER:www-data $PROJECT_ROOT
sudo chmod -R 775 $PROJECT_ROOT

# Check index.php file
echo "<?php phpinfo(); ?>" | sudo tee $PROJECT_ROOT/index.php > /dev/null

# Create nginx file config for project
print_message "yellow" "Nginx config creating..."
NGINX_CONFIG="/etc/nginx/sites-available/myproject"
sudo tee $NGINX_CONFIG > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    root $PROJECT_ROOT;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Check Nginx configuration
sudo ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
fi

sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
else
    print_message "red" "Error in Nginx config. please check."
    exit 1
fi

# Istall Composer
print_message "yellow" "Installing Composer..."
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    print_message "red" "Error: verify Composer failed!"
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
sudo mv composer.phar /usr/local/bin/composer
rm composer-setup.php
print_message "green" "Composer installation done."

# Check and show service status
print_message "yellow" "Service status:"
echo "---------------------------------"
echo "Nginx status:"
sudo systemctl status nginx --no-pager
echo "---------------------------------"
echo "PHP-FPM status:"
sudo systemctl status php${PHP_VERSION}-fpm --no-pager
echo "---------------------------------"
echo "MySQL status:"
sudo systemctl status mysql --no-pager
echo "---------------------------------"

# Show server ip
SERVER_IP=$(hostname -I | awk '{print $1}')
print_message "green" "Server config done:"
echo "http://${SERVER_IP}/"
