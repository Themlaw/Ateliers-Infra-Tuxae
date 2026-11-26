#!/usr/bin/env python3
import json
import re
import sys
import urllib.error
import urllib.request
import time
from pathlib import Path

v = dict(re.findall(r'^\s*(\w+)\s*=\s*"([^"]*)"', Path(sys.argv[1]).read_text(), re.M))
nom = v.get("image_poste_name", "atelier-poste")

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

def appel(methode, url):
    r = urllib.request.Request(url, method=methode, headers={"X-Auth-Token": jeton})
    with urllib.request.urlopen(r) as rep:
        return json.load(rep) if methode == "GET" else None

total = 0
for e in next(s for s in catalogue if s["type"] == "image")["endpoints"]:
    if e["interface"] != "public":
        continue
    base = e["url"].rstrip("/")
    for essai in range(5):  # le DNS local peut lâcher : on réessaie avant d'abandonner
        try:
            images = appel("GET", f"{base}/v2/images?name={nom}&visibility=private")["images"]
            break
        except urllib.error.URLError as err:
            print(f"{e['region_id']} : injoignable ({err}), nouvel essai")
            time.sleep(10)
    else:
        sys.exit(f"{e['region_id']} : toujours injoignable, images NON vérifiées : relance la commande")
    for img in images:
        appel("DELETE", f"{base}/v2/images/{img['id']}")
        print(f"{e['region_id']} : image {nom} {img['id']} supprimée")
        total += 1
print(f"{total} image(s) supprimée(s).")
