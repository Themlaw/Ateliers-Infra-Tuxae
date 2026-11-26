#!/usr/bin/env bash
set -euxo pipefail

install -m 0755 /tmp/atelier/bin/atelier-progres /usr/local/bin/atelier-progres
install -m 0755 /tmp/atelier/bin/calcul-mystere  /usr/local/bin/calcul-mystere
install -m 0644 /tmp/atelier/systemd/*.service /tmp/atelier/systemd/*.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable atelier-progres.timer calcul-mystere.service

python3 /tmp/atelier/generer_missions.py /home/eleve

cat >> /home/eleve/.bashrc <<'BASHRC'

PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
HISTSIZE=5000
HISTFILESIZE=5000
BASHRC
chown -R eleve:eleve /home/eleve

chmod -x /etc/update-motd.d/* || true
install -m 0644 /tmp/atelier/motd /etc/motd
