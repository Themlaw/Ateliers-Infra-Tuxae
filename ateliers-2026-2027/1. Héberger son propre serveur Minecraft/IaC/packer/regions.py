#!/usr/bin/env python3
import json
import re
import sys
import urllib.request
from pathlib import Path

texte = Path(sys.argv[1]).read_text()
v = dict(re.findall(r'^\s*(\w+)\s*=\s*"([^"]*)"', texte, re.M))
liste = re.search(r'^\s*postes_regions\s*=\s*\[([^\]]*)\]', texte, re.M)
regions = (re.findall(r'"([^"]+)"', liste.group(1)) if liste else []) or [v["os_region"]]
reseau = v.get("os_ext_net_name", "Ext-Net")

corps = {"auth": {
    "identity": {"methods": ["password"], "password": {"user": {
        "name": v["os_username"], "domain": {"name": "Default"}, "password": v["os_password"]}}},
    "scope": {"project": {"id": v["os_project_id"]}}}}
req = urllib.request.Request(v["os_auth_url"].rstrip("/") + "/auth/tokens",
                             data=json.dumps(corps).encode(),
                             headers={"Content-Type": "application/json"})
with urllib.request.urlopen(req) as rep:
    jeton = rep.headers["X-Subject-Token"]
    catalogue = json.load(rep)["token"]["catalog"]

reseaux = next(s for s in catalogue if s["type"] == "network")["endpoints"]
for region in regions:
    url = next(e["url"] for e in reseaux if e["region_id"] == region and e["interface"] == "public")
    req = urllib.request.Request(f"{url.rstrip('/')}/v2.0/networks?name={reseau}",
                                 headers={"X-Auth-Token": jeton})
    with urllib.request.urlopen(req) as rep:
        trouves = json.load(rep)["networks"]
    if not trouves:
        sys.exit(f"Réseau {reseau} introuvable en {region}")
    print(region, trouves[0]["id"])
