#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait || true

apt-get update
apt-get -y upgrade
apt-get install -y --no-install-recommends \
  docker.io docker-compose-v2 ttyd fail2ban rsyslog nftables \
  jq htop tree nano less curl unzip python3 gpg ca-certificates

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
  > /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y alloy

id eleve 2>/dev/null || useradd -m -s /bin/bash -G docker,adm,sudo eleve

cat > /etc/systemd/system/ttyd.service <<'EOF'
[Unit]
Description=Terminal web (ttyd) pour l'atelier
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/ttyd -p 7681 -W -t fontSize=16 -t titleFixed=Tuxae login
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/fail2ban/jail.d/atelier.conf <<'EOF'
[sshd]
enabled = true
backend = auto
logpath = /var/log/auth.log
maxretry = 5
bantime = 1h
EOF

systemctl daemon-reload
systemctl enable docker ttyd fail2ban rsyslog alloy
