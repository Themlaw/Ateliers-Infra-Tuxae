#!/usr/bin/env bash
set -euo pipefail
config="$1"

packer init .
lignes="$(python3 regions.py "$config")"

pids=()
while read -r region net; do
  echo "Construction de l'image en $region…"
  ( for essai in 1 2; do
      packer build -var "os_region=$region" -var "os_ext_net_id=$net" . 2>&1 | sed -u "s/^/[$region] /" && exit 0
      echo "[$region] échec de l'essai $essai"; sleep 30
    done; exit 1 ) &
  pids+=("$!")
done <<< "$lignes"

echec=0
for pid in "${pids[@]}"; do wait "$pid" || echec=1; done
[ "$echec" -eq 0 ] || { echo "Au moins une région a échoué (voir les lignes [RÉGION] ci-dessus)."; exit 1; }
