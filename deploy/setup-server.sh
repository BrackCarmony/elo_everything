#!/usr/bin/env bash
# One-time setup for a fresh Ubuntu 24.04 droplet. Run as root on the server:
#   ssh root@<ip> 'bash -s' < deploy/setup-server.sh
# Installs Ruby (built with ruby-build), Postgres, nginx and certbot, creates the "elo" app user
# and database, adds swap (1 GB droplets need it to build Ruby and precompile assets),
# and installs the systemd service and nginx site.
set -euo pipefail

RUBY_VERSION="${RUBY_VERSION:-4.0.7}"
APP=elo_everything
APP_USER=elo
APP_DIR=/srv/$APP

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y build-essential git curl autoconf bison libssl-dev libyaml-dev libreadline-dev zlib1g-dev \
  libffi-dev libgdbm-dev libpq-dev postgresql nginx certbot python3-certbot-nginx ufw

if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

if [ ! -x /opt/rubies/$RUBY_VERSION/bin/ruby ]; then
  rm -rf /tmp/ruby-build && git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build
  /tmp/ruby-build/bin/ruby-build "$RUBY_VERSION" /opt/rubies/$RUBY_VERSION
fi
ln -sfn /opt/rubies/$RUBY_VERSION /opt/rubies/current

id -u $APP_USER >/dev/null 2>&1 || useradd --create-home --shell /bin/bash $APP_USER
mkdir -p $APP_DIR/releases $APP_DIR/shared/{config,log,tmp,bundle,storage}
chown -R $APP_USER:$APP_USER $APP_DIR

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$APP_USER'" | grep -q 1 || sudo -u postgres createuser --createdb $APP_USER

cat > /etc/systemd/system/$APP.service <<UNIT
[Unit]
Description=Elo Everything (Rails/Puma)
After=network.target postgresql.service

[Service]
User=$APP_USER
WorkingDirectory=$APP_DIR/current
Environment=RAILS_ENV=production
Environment=PORT=3000
Environment=BUNDLE_PATH=$APP_DIR/shared/bundle
Environment=BUNDLE_DEPLOYMENT=1
Environment=BUNDLE_WITHOUT=development:test
Environment=PATH=/opt/rubies/current/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/opt/rubies/current/bin/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable $APP

cat > /etc/nginx/sites-available/$APP <<'NGINX'
upstream elo_puma { server 127.0.0.1:3000; }

server {
  listen 80;
  server_name elo.brackcarmony.com;
  root /srv/elo_everything/current/public;

  location /assets/ {
    expires max;
    add_header Cache-Control "public, immutable";
    try_files $uri =404;
  }

  location / {
    try_files $uri @app;
  }

  location @app {
    proxy_pass http://elo_puma;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
NGINX
ln -sfn /etc/nginx/sites-available/$APP /etc/nginx/sites-enabled/$APP
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

ufw allow OpenSSH && ufw allow 'Nginx Full' && ufw --force enable

# The deploy script runs restarts as the app user.
echo "$APP_USER ALL=(root) NOPASSWD: /usr/bin/systemctl restart $APP, /usr/bin/systemctl is-active $APP" > /etc/sudoers.d/$APP
chmod 440 /etc/sudoers.d/$APP

echo "Server ready. Next: copy config/master.key, run bin/deploy, then certbot --nginx -d elo.brackcarmony.com"
