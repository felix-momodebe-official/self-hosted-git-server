## Deploying a Self-Hosted Git Server with Gitea on AWS EC2!

In today's development landscape, having control over your own source code management platform can be a game-changer. 
I recently deployed a self-hosted Git server using Gitea on an AWS EC2 Ubuntu instance, complete with a custom domain and SSL encryption. 
Here’s how I did it! 👇

## Architectural Visualization:

![image](https://github.com/user-attachments/assets/8d914868-6c6a-418c-a85c-d299fad909af)


## 🎯 Project Objective

The goal was to deploy a private Git repository hosting solution that supports:
- ✅ User management
- ✅ CI/CD automation
- ✅ SSH and HTTPS access
- ✅ Secure repository hosting

Gitea is an excellent lightweight alternative to GitHub/GitLab, and this setup ensures full control over the development workflow.

## 📌 Deliverables

- ✅ Fully functional self-hosted Git server
- ✅ Configured for SSH and HTTPS access
- ✅ Reverse proxy with Nginx
- ✅ Secured with Let’s Encrypt SSL
- ✅ Automated database and system service setup

## ⚙️ Requirements & Prerequisites

Before starting, make sure you have:

- ✅ An AWS EC2 instance (Ubuntu 20.04/22.04)
- ✅ A domain name (e.g., git.succpinndemo.com)
- ✅ Basic knowledge of Linux commands
- ✅ Security groups allowing ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
- ✅ mariadb server

## 🔥 Step-by-Step Deployment Process

### 1️⃣ Spin up an Ubunt EC2 machine. SSH into the machine, Update & Install Dependencies

![image](https://github.com/user-attachments/assets/52369536-b32e-4d32-9ed3-681e2adb97ef)

#### Update & Install Dependencies:

```
sudo apt update && sudo apt upgrade -y
sudo apt install git mariadb-server nginx certbot python3-certbot-nginx -y
```

### 2️⃣ Secure MariaDB & Create Database

#### Secure MariaDB:

 `sudo mysql_secure_installation`


#### Create Gitea Database & User

- Login into Database
  
`sudo mysql -u root -p`

- Create Database & User

```
CREATE DATABASE gitea CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci';
CREATE USER 'gitea'@'localhost' IDENTIFIED BY 'Devopsshack@123';
GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3️⃣ Install & Configure Gitea

#### Download & Install Gitea

```
sudo mkdir -p /var/lib/gitea
sudo useradd --system --home /var/lib/gitea --shell /bin/bash gitea
sudo wget -O /usr/local/bin/gitea https://dl.gitea.com/gitea/1.23.4/gitea-1.23.4-linux-amd64
sudo chmod +x /usr/local/bin/gitea
```

### 4️⃣ Set Up Configuration & Permissions / Create Configuration & Data Directories

```
sudo mkdir -p /etc/gitea /var/lib/gitea/{custom,data,log}
sudo chown -R gitea:gitea /var/lib/gitea /etc/gitea
sudo chmod -R 750 /var/lib/gitea /etc/gitea
sudo touch /etc/gitea/app.ini
sudo chmod 640 /etc/gitea/app.ini
```

### Configure app.ini (Update /etc/gitea/app.ini with):

#### Open the Gitea configuration file:

`sudo vi /etc/gitea/app.ini`

#### Update Repository Paths

```
[repository]
ROOT = /var/lib/gitea/data/gitea-repositories

[server]
DOMAIN = git.succpinndemo.com
SSH_DOMAIN = git.succpinndemo.com
HTTP_PORT = 3000
ROOT_URL = https://git.succpinndemo.com/
LFS_CONTENT_PATH = /var/lib/gitea/data/fs

[log]
ROOT_PATH = /var/lib/gitea/log
```

#### Then, fix permissions:

```
sudo chown -R gitea:gitea /etc/gitea
sudo chmod 640 /etc/gitea/app.ini
```

### 5️⃣ Configure / Set Up Systemd Service for Gitea

`sudo vi /etc/systemd/system/gitea.service`

#### Paste the following:

```
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
```
#### Reload Systemd & Start Gitea:

```
sudo systemctl daemon-reload
sudo systemctl enable --now gitea
sudo systemctl status gitea
```

### 6️⃣ Configure Nginx Reverse Proxy / Set Up Reverse Proxy with Nginx

`sudo vi /etc/nginx/sites-available/gitea`

```
server {
    listen 80;
    server_name git.succpinndemo.com;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
    }
}
```

### 7️⃣ Enable & Restart Nginx:

```
sudo ln -s /etc/nginx/sites-available/gitea /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

### 8️⃣ Secure with SSL (Let’s Encrypt)

`sudo certbot --nginx -d git.succpinndemo.com`

### 9️⃣ Set & Add up auto-renewal:

```
sudo crontab -e
0 3 * * * certbot renew --quiet
```
### 10. Enable SSH Access for Git Repositories

```
sudo usermod -aG gitea $(whoami)
sudo systemctl restart gitea
git clone git@git.succpinndemo.com:your-username/your-repo.git
```

### 11. Access Gitea Web Interface

- 🌐 Open `https://git.succpinndemo.com` in a browser.
- ✅ Complete initial setup.
- ✅ Use database credentials from step 2.
- ✅ Create an admin user and start managing repositories!

![image](https://github.com/user-attachments/assets/ff69af23-2510-4cfb-ad5d-88dcdb6538f8)

![image](https://github.com/user-attachments/assets/e5a4b59b-c3b1-4d16-a033-7c324e0b04cd)

#### Click **Register** at the top right to register:

![image](https://github.com/user-attachments/assets/96a1ed2d-51e0-47ef-9ab5-e00470bc969d) 

![image](https://github.com/user-attachments/assets/7673ebc1-12e9-48f0-bfa4-aa52677f8c5d)

#### Create your first repo:

![image](https://github.com/user-attachments/assets/243d2bd0-d6c3-4729-b1de-d43bd0920055)






## 🔥 Key Takeaways

- ✅ Gitea provides **lightweight, self-hosted Git repository management.**
- ✅ **Nginx reverse proxy** enables **secure** and **easy access** via a domain.
- ✅ Let’s Encrypt **SSL integration** ensures **encrypted communication**.
- ✅ **Fully automated setup** with systemd & auto-renewing certificates.




