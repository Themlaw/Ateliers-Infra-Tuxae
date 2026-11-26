#!/usr/bin/env bash
set -euxo pipefail

apt-get clean
rm -rf /tmp/atelier /tmp/mcgalaxy

truncate -s 0 /var/log/auth.log || true
rm -f /var/log/fail2ban.log*
journalctl --rotate && journalctl --vacuum-time=1s || true

rm -f /home/eleve/.bash_history /root/.bash_history
cloud-init clean --logs --seed
