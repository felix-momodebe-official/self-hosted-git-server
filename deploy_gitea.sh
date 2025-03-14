#!/bin/bash

# Variables
GITEA_VERSION="1.23.4"
DOMAIN="git.succpinndemo.com"
DB_USER="gitea"
DB_PASS="Devopsshack@123"
DB_NAME="gitea"

# Update & Upgrade System
echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# Install Required Packages
echo "Installing required packages..."
sudo apt install -y git mariadb-server nginx certbot python3-certbot-nginx wget

# Secure MariaDB
echo "Securing MariaDB..."
sudo mysql_secure_installation <<EOF

y
$DB_PASS
$DB_PASS
y
y
y
y
EOF

# Create Gitea Database & User
echo "Creating Gitea database and user..."
sudo mysql -u root -p$DB_PASS <<EOF
CREATE DATABASE $DB_NAME CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Install & Configure Gitea
echo "Installing Gitea..."
sudo mkdir -p /var/lib/gitea
sudo useradd --system --home /var/lib/gitea --shell /bin/bash gitea
sudo wget -O /usr/local/bin/gitea https://dl.gitea.com/gitea/$GITEA_VERSION/gitea-$GITEA_VERSION-linux-amd64
sudo chmod +x /usr/local/bin/gitea

# Create Configuration & Data Directories
echo "Configuring Gitea directories..."
sudo mkdir -p /etc/gitea /var/lib/gitea/{custom,data,log}
sudo chown -R gitea:gitea /var/lib/gitea /etc/gitea
sudo chmod -R 750 /var/lib/gitea /etc/gitea
sudo touch /etc/gitea/app.ini
sudo chmod 640 /etc/gitea/app.ini

# Configure Gitea settings
echo "Writing app.ini configuration..."
sudo tee /etc/gitea/app.ini > /dev/null <<EOF
[repository]
ROOT = /var/lib/gitea/data/gitea-repositories

[server]
APP_DATA_PATH = /var/lib/gitea/data
DOMAIN = $DOMAIN
SSH_DOMAIN = $DOMAIN
HTTP_PORT = 3000
ROOT_URL = https://$DOMAIN/
LFS_CONTENT_PATH = /var/lib/gitea/data/fs

[log]
ROOT_PATH = /var/lib/gitea/log
EOF

sudo chown -R gitea:gitea /etc/gitea
sudo chmod 640 /etc/gitea/app.ini

# Configure Systemd Service for Gitea
echo "Setting up Gitea systemd service..."
sudo tee /etc/systemd/system/gitea.service > /dev/null <<EOF
[Unit]
Description=Gitea Self-Hosted Git Server
After=network.target mariadb.service

[Service]
User=gitea
Group=gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
WorkingDirectory=/var/lib/gitea
Environment=USER=gitea HOME=/var/lib/gitea

[Install]
WantedBy=multi-user.target
EOF

# Reload Systemd & Start Gitea
echo "Starting Gitea service..."
sudo systemctl daemon-reload
sudo systemctl enable --now gitea
sudo systemctl status gitea --no-pager

# Set Up Reverse Proxy with Nginx
echo "Configuring Nginx as reverse proxy..."
sudo tee /etc/nginx/sites-available/gitea > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
    }
}
EOF

# Enable Nginx Config & Restart
sudo ln -s /etc/nginx/sites-available/gitea /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Secure Gitea with SSL (Let's Encrypt)
echo "Setting up SSL with Certbot..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# Enable SSL Auto-Renewal
echo "Setting up SSL auto-renewal..."
echo "0 3 * * * certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null

echo "Gitea installation and setup completed successfully!"

