import hashlib
import hmac
import json
import os
import socket
import sqlite3
import threading
import time
from pathlib import Path

from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

DATA = Path(os.environ.get("MUR_DATA", "/data"))
POSTES_JSON = DATA / "postes.json"
DB = DATA / "progress.db"
ETAPES = ["Découvrir", "Logs", "Processus", "Serveur", "Config", "Bonus sécurité"]
NB_QUETES = len(ETAPES)
ADMIN = os.environ.get("MUR_ADMIN_PASSWORD", "")

app = FastAPI(title="Mur Tuxae")
_lock = threading.Lock()
_cache = {"mtime": 0.0, "data": {"jeu": "", "domain": "", "postes": []}}
_en_ligne: dict[str, bool] = {}

def db() -> sqlite3.Connection:
    con = sqlite3.connect(DB)
    con.execute("CREATE TABLE IF NOT EXISTS progres (poste TEXT, quete INTEGER, ts REAL, PRIMARY KEY (poste, quete))")
    con.execute("CREATE TABLE IF NOT EXISTS pseudos (poste TEXT PRIMARY KEY, pseudo TEXT)")
    return con

def postes() -> dict:
    try:
        mtime = POSTES_JSON.stat().st_mtime
    except FileNotFoundError:
        return _cache["data"]
    if mtime != _cache["mtime"]:
        _cache["data"] = json.loads(POSTES_JSON.read_text())
        _cache["mtime"] = mtime
    return _cache["data"]

def sonde() -> None:
    while True:
        for p in postes().get("postes", []):
            try:
                with socket.create_connection((p["ip"], 25565), timeout=1):
                    _en_ligne[p["nom"]] = True
            except OSError:
                _en_ligne[p["nom"]] = False
        time.sleep(15)

threading.Thread(target=sonde, daemon=True).start()

class Validation(BaseModel):
    poste: str
    token: str
    quete: int = Field(ge=1, le=NB_QUETES)
    pseudo: str = ""

@app.post("/api/valider")
def valider(v: Validation):
    p = next((x for x in postes().get("postes", []) if x["nom"] == v.poste), None)
    if p is None:
        raise HTTPException(404, "poste inconnu")
    attendu = p["token_sha256"]
    recu = hashlib.sha256(v.token.encode()).hexdigest()
    if not hmac.compare_digest(attendu, recu):
        raise HTTPException(403, "jeton invalide")
    with _lock, db() as con:
        con.execute("INSERT OR IGNORE INTO progres VALUES (?, ?, ?)", (v.poste, v.quete, time.time()))
        if v.pseudo:
            con.execute("INSERT OR REPLACE INTO pseudos VALUES (?, ?)", (v.poste, v.pseudo[:24]))
    return {"ok": True}

@app.get("/api/etat")
def etat():
    data = postes()
    with _lock, db() as con:
        progres = con.execute("SELECT poste, quete, ts FROM progres").fetchall()
        pseudos = dict(con.execute("SELECT poste, pseudo FROM pseudos").fetchall())
    faites: dict[str, list[int]] = {}
    for poste, quete, _ in progres:
        faites.setdefault(poste, []).append(quete)
    return {
        "jeu": data.get("jeu"),
        "domain": data.get("domain"),
        "nb_quetes": NB_QUETES,
        "etapes": ETAPES,
        "postes": [
            {
                "nom": p["nom"],
                "num": p["num"],
                "pseudo": pseudos.get(p["nom"], ""),
                "quetes": sorted(faites.get(p["nom"], [])),
                "en_ligne": _en_ligne.get(p["nom"], False),
            }
            for p in sorted(data.get("postes", []), key=lambda x: x["num"])
        ],
    }

@app.post("/api/reset")
def reset(x_admin: str = Header(default="")):
    if not ADMIN or not hmac.compare_digest(x_admin, ADMIN):
        raise HTTPException(403, "mot de passe admin invalide")
    with _lock, db() as con:
        con.execute("DELETE FROM progres")
        con.execute("DELETE FROM pseudos")
    return {"ok": True}

PAGE = """<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"><title>Mur — Atelier Infra Tuxae</title>
<style>
  :root { color-scheme: dark; }
  body { margin: 0; padding: 24px 32px; background: #0f1115; color: #e8e8e8;
         font-family: system-ui, sans-serif; }
  h1 { margin: 0 0 4px; font-size: 34px; }
  .sous { color: #9aa0a6; margin-bottom: 20px; font-size: 18px; }
  table { border-collapse: separate; border-spacing: 4px; width: 100%; }
  th { color: #9aa0a6; font-weight: 500; font-size: 15px; }
  td { padding: 6px 8px; font-size: 18px; }
  td.case { width: 90px; height: 30px; border-radius: 6px; background: #22262e; text-align: center; }
  td.ok { background: #2e9e5b; }
  td.srv-on { background: #2e7dd1; }
  .nom { font-weight: 600; white-space: nowrap; }
  .pseudo { color: #f2c94c; }
  .score { font-variant-numeric: tabular-nums; color: #9aa0a6; }
</style></head>
<body>
<h1>Atelier Infra/DevOps — le mur</h1>
<div class="sous" id="sous">Chargement…</div>
<table><thead id="tete"></thead><tbody id="corps"></tbody></table>
<script>
async function maj() {
  try {
    const r = await fetch('/api/etat'); const e = await r.json();
    const n = e.nb_quetes;
    let t = '<tr><th></th>';
    for (let i = 1; i <= n; i++) t += '<th>' + i + '. ' + e.etapes[i - 1] + '</th>';
    t += '<th>En ligne</th><th></th></tr>';
    document.getElementById('tete').innerHTML = t;
    let c = '', fini = 0, enligne = 0;
    for (const p of e.postes) {
      const pseudo = p.pseudo ? ' <span class="pseudo">' + p.pseudo.replace(/[<>&]/g, '') + '</span>' : '';
      c += '<tr><td class="nom">Poste ' + p.num + pseudo + '</td>';
      for (let i = 1; i <= n; i++) c += '<td class="case' + (p.quetes.includes(i) ? ' ok' : '') + '"></td>';
      c += '<td class="case' + (p.en_ligne ? ' srv-on' : '') + '"></td>';
      c += '<td class="score">' + p.quetes.length + '/' + n + '</td></tr>';
      if (p.quetes.length === n) fini++;
      if (p.en_ligne) enligne++;
    }
    document.getElementById('corps').innerHTML = c;
    document.getElementById('sous').textContent =
      e.postes.length + ' postes · ' + enligne + ' serveurs en ligne · ' + fini + ' ont tout fini';
  } catch (err) { document.getElementById('sous').textContent = 'Mur injoignable…'; }
}
maj(); setInterval(maj, 3000);
</script>
</body></html>"""

@app.get("/", response_class=HTMLResponse)
def mur():
    return PAGE
