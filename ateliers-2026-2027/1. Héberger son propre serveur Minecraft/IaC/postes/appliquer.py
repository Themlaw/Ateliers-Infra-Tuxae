#!/usr/bin/env python3
import json
import re
import os
import subprocess
import sys
import time
from pathlib import Path

ESSAIS = 6
ICI = Path(__file__).resolve().parent
FICHIER = ICI / "regions.auto.tfvars.json"
TOFU = os.environ.get("TOFU", "tofu")  # le Makefile peut passer outils/tofu-dns-public

def lire_config(args):
    var_file = next((a.split("=", 1)[1] for a in args if a.startswith("-var-file=")), None)
    texte = Path(var_file).read_text() if var_file else ""
    liste = re.search(r'^\s*postes_regions\s*=\s*\[([^\]]*)\]', texte, re.M)
    regions = re.findall(r'"([^"]+)"', liste.group(1)) if liste else []
    if not regions:
        seule = re.search(r'^\s*os_region\s*=\s*"([^"]+)"', texte, re.M)
        regions = [seule.group(1)] if seule else []
    return regions

def postes_en_echec():
    sortie = subprocess.run([TOFU, "show", "-json"], cwd=ICI, capture_output=True, text=True)
    if sortie.returncode != 0 or not sortie.stdout.strip():
        return []
    ressources = json.loads(sortie.stdout).get("values", {}).get("root_module", {}).get("resources", [])
    return [r["index"] for r in ressources
            if r.get("type") == "openstack_compute_instance_v2" and r.get("tainted")]

def main():
    args = sys.argv[1:]
    regions = lire_config(args)
    placement = json.loads(FICHIER.read_text()).get("poste_region", {}) if FICHIER.exists() else {}

    for essai in range(1, ESSAIS + 1):
        if subprocess.run([TOFU, "apply", "-auto-approve", *args], cwd=ICI).returncode == 0:
            return 0
        echecs = postes_en_echec()
        if len(regions) > 1 and echecs:
            for nom in echecs:
                actuelle = placement.get(nom, regions[0])
                suivante = regions[(regions.index(actuelle) + 1) % len(regions)] if actuelle in regions else regions[0]
                placement[nom] = suivante
                print(f"  {nom} : pas de place en {actuelle}, essai en {suivante}")
            FICHIER.write_text(json.dumps({"poste_region": placement}, indent=2) + "\n")
            pause = 10
        else:
            pause = 60
        if essai < ESSAIS:
            print(f"Essai {essai}/{ESSAIS} échoué, nouvel essai dans {pause} s…", flush=True)
            time.sleep(pause)
    return 1

if __name__ == "__main__":
    sys.exit(main())
