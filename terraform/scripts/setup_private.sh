#!/bin/bash
dnf update -y
dnf install -y docker
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
systemctl start docker
systemctl enable --now docker
mkdir -p /home/ec2-user/nextcloud && cd /home/ec2-user/nextcloud

cat <<EOF > docker-compose.yml
services:
  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=nc_pass
      - POSTGRES_DB=nextcloud
      - POSTGRES_USER=nextcloud
      restart: always
EOF
docker-compose up -d
