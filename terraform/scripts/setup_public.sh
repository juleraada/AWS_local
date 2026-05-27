#!/bin/bash
dnf update -y
dnf install -y docker
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
systemctl start docker
systemctl enable --now docker
mkdir -p /home/ec2-user/app && cd /home/ec2-user/app

# Crear config de Nginx como Balanceador de Carga
cat <<'EOF' > nginx.conf
events {}

http {

    upstream nextcloud_backend {
        server 10.0.2.110:80;
        server 10.0.2.120:80;
    }

    server {

        listen 80;

        # -------------------------
        # GITEA
        # -------------------------
        location /gitea/ {

            proxy_pass http://gitea:3000/;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # -------------------------
        # VSCODE / CODE-SERVER
        # -------------------------
        location /vscode/ {

            proxy_pass http://vscode:8080/;

            proxy_http_version 1.1;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # -------------------------
        # NEXTCLOUD
        # -------------------------
        location /nextcloud/ {

            rewrite ^/nextcloud/(.*)$ /$1 break;

            proxy_pass http://nextcloud_backend;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}

EOF

# Docker Compose
cat <<'EOF' > docker-compose.yml
  GNU nano 8.3                                             docker-compose.yml                                                        
services:

  nginx:
    image: nginx:latest

    container_name: nginx

    ports:
      - "80:80"

    volumes:
      - "./nginx.conf:/etc/nginx/nginx.conf:ro"

    depends_on:
      - gitea
      - vscode

    restart: unless-stopped

  gitea:
    image: gitea/gitea:latest

    container_name: gitea

    ports:
      - "3000:3000"
      - "222:22"

    volumes:
      - "./data:/data"

    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__server__ROOT_URL=http://34.238.43.82/gitea/

    restart: unless-stopped

  vscode:
    image: codercom/code-server:latest

    container_name: vscode

    ports:
      - "8080:8080"

    environment:
      - PASSWORD=demo123

    restart: unless-stopped
EOF
docker-compose up -d
