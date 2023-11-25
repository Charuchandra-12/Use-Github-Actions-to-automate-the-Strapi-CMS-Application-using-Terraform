#!/bin/bash

public_ip=""
# Check if (public IP) is provided
if [ -n "$1" ]; then
    public_ip="$1"
    echo "Public IP Address: $public_ip"

else
    echo "Error: Public IP address not provided."
fi

# Update the package repository
sudo apt-get update

# Install expect for automation
sudo apt install expect -y

# Set timeout for expect
set timeout -1

# Install Node.js using nsolid_setup_deb.sh
curl -SLO https://deb.nodesource.com/nsolid_setup_deb.sh
chmod 500 nsolid_setup_deb.sh
./nsolid_setup_deb.sh 20
apt-get install nodejs -y

# Install PostgreSQL
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql

# Install Nginx
sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'

# Configure Nginx
sudo tee "/etc/nginx/sites-available/${public_ip}" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${public_ip} www.${public_ip};

    location / {
        proxy_pass http://localhost:1337;
        include proxy_params;
    }
}
EOF

sudo ln -s "/etc/nginx/sites-available/${public_ip}" /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Create PostgreSQL database
sudo -i -u postgres createdb strapi-db

# Configure PostgreSQL
expect <<'END_EXPECT'
spawn sudo -i -u postgres createuser --interactive

expect "Enter name of role to add:"
send "chinmay\r"

expect "Shall the new role be a superuser? (y/n)"
send "y\r"

expect eof
END_EXPECT

# Set PostgreSQL user password
sudo -u postgres psql <<EOF
ALTER USER chinmay PASSWORD 'postgres_passcode';
\q
EOF

# create a Strapi app project
expect <<'END_EXPECT'
spawn npx create-strapi-app@latest chinmay-project

expect "Ok to proceed?"
send "\r"

expect "Choose your installation type"
send "\033\[B" ; send "\r"

expect "Choose your preferred language"
send "\r"

expect "Choose your default database client"
send "\033\[B" ; send "\r"

expect "Database name:"
send "strapi-db\r"

expect "Host:"
send "\r"

expect "Port:"
send "\r"

expect "Username:"
send "chinmay\r"

expect "Password:"
send "postgres_passcode\r"

expect "Enable SSL connection:"
send "N\r"

expect eof
END_EXPECT

# build and run the strapi server
cd /home/ubuntu/chinmay-project
npm install
NODE_ENV=production npm run build
nohup node /home/ubuntu/chinmay-project/node_modules/.bin/strapi start > /dev/null 2>&1 &



