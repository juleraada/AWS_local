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

  app:
    image: nextcloud:29

    container_name: nextcloud

    ports:
      - "80:80"

    volumes:
      - "./nextcloud:/var/www/html"

    environment:
      - POSTGRES_HOST=10.0.2.100
      - POSTGRES_DB=nextcloud
      - POSTGRES_USER=nextcloud
      - POSTGRES_PASSWORD=nc_pass

      - NEXTCLOUD_ADMIN_USER=admin
      - NEXTCLOUD_ADMIN_PASSWORD=ProyectoNC123

      - NEXTCLOUD_TRUSTED_DOMAINS=44.202.35.32

      - TRUSTED_PROXIES=10.0.1.0/24

      - OVERWRITEHOST=44.202.35.32
      - OVERWRITEPROTOCOL=http
      - OVERWRITEWEBROOT=/nextcloud

      - APACHE_DISABLE_REWRITE_IP=1

    restart: unless-stopped

EOF
docker-compose up -d
