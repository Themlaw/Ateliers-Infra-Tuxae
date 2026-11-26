#!/usr/bin/env bash
set -euxo pipefail

docker pull itzg/minecraft-server:latest
install -d /opt/atelier/mc-seed
docker run --rm \
  -e EULA=TRUE -e TYPE=PAPER -e VERSION="${MC_VERSION}" -e SETUP_ONLY=true \
  -v /opt/atelier/mc-seed:/data \
  itzg/minecraft-server:latest
regler() { grep -q "^$1=" "$3" && sed -i "s/^$1=.*/$1=$2/" "$3" || echo "$1=$2" >> "$3"; }
for kv in online-mode=false difficulty=peaceful view-distance=6 simulation-distance=6; do
  regler "${kv%%=*}" "${kv#*=}" /opt/atelier/mc-seed/server.properties
done
paper_jar="$(basename "$(ls /opt/atelier/mc-seed/paper-*.jar | head -n 1)")"
docker run --rm -v /opt/atelier/mc-seed:/data -w /data --entrypoint java \
  itzg/minecraft-server:latest -Dpaperclip.patchonly=true -jar "/data/${paper_jar}"

docker build -t tuxae/mcgalaxy:latest /tmp/mcgalaxy
