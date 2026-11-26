#!/usr/bin/env python3
import os
import random
import sys
from datetime import datetime, timedelta
from pathlib import Path

HOME = Path(sys.argv[1])
M = HOME / "missions"
MC_VERSION = os.environ.get("MC_VERSION", "1.20.4")
random.seed(26112026)

def ecrire(chemin: Path, texte: str, mode: int = 0o644) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(texte, encoding="utf-8")
    os.chmod(chemin, mode)

ecrire(M / "LISEZMOI.txt", """\
=====================================================================
  Cette machine est à toi pour l'après-midi. Elle tourne chez OVH,
  dans un datacenter, comme les serveurs des sites que tu utilises.
=====================================================================

Chaque mission est une situation réelle d'administrateur système.
Rien à valider : le mur, au vidéoprojecteur, voit tout seul ce que tu fais.

 1. Découvrir la machine          cat ~/missions/1-decouvrir.txt
 2. Le site a eu une panne        cat ~/missions/2-logs.txt
 3. La machine rame               cat ~/missions/3-processus.txt
 4. Lancer ton serveur de jeu     cat ~/missions/4-serveur.txt
 5. Le personnaliser              cat ~/missions/5-config.txt
 Bonus : qui frappe à la porte ?  cat ~/missions/bonus-securite.txt

Astuces : la touche Tab complète les noms, flèche du haut = commande précédente,
Ctrl+C arrête une commande, et  man <commande>  affiche son mode d'emploi.
""")

ecrire(M / "1-decouvrir.txt", """\
--- 1. Découvrir la machine ------------------------------------------

On te confie un serveur que tu n'as jamais vu : on regarde où on est.

  Où suis-je ?                 pwd
  Qu'y a-t-il ici ?            ls          (ls -l pour les détails)
  Entrer dans un dossier :     cd logs     revenir :  cd ..     chez soi :  cd
  Lire un fichier :            cat /etc/os-release

Question : quel système tourne sur ta machine ?
""")

ecrire(M / "3-processus.txt", """\
--- 3. La machine rame -----------------------------------------------

Un programme inconnu mange le processeur depuis le démarrage.

  Voir les programmes en direct :   htop      (q pour quitter)

Repère son nom et son numéro (colonne PID), puis arrête-le :   kill <PID>
Vérifie dans htop que le processeur respire.
""")

jour = datetime(2026, 11, 25)
pages = ["/", "/", "/", "/classement", "/classement", "/api/scores", "/api/scores",
         "/static/app.js", "/static/style.css", "/favicon.ico", "/connexion", "/profil"]
navigateurs = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148",
]
visiteurs = [f"{random.choice([78, 82, 88, 90, 92, 109, 176, 193])}.{random.randrange(1, 255)}."
             f"{random.randrange(1, 255)}.{random.randrange(1, 255)}" for _ in range(400)]
ROBOT = "185.220.101.47"
SCANNERS = ["45.148.10.12", "193.32.162.85", "167.94.138.60"]
debut_panne = jour.replace(hour=14, minute=2)
fin_panne = jour.replace(hour=14, minute=9, second=30)

entrees = []  # (date, ligne)

def ligne(ip, t, methode, chemin, statut, taille, agent):
    d = t.strftime("%d/%b/%Y:%H:%M:%S +0100")
    return f'{ip} - - [{d}] "{methode} {chemin} HTTP/1.1" {statut} {taille} "-" "{agent}"'

for _ in range(18_000):
    h = random.choices(range(24), weights=[1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 6, 8, 9, 10, 9, 8, 8, 9, 10, 10, 8, 5, 2])[0]
    t = jour + timedelta(hours=h, seconds=random.randrange(3600))
    p = random.choice(pages)
    statut = random.choices([200, 304, 404], weights=[90, 8, 2])[0]
    if p == "/api/scores" and debut_panne <= t <= fin_panne:
        statut = 500
    taille = 0 if statut == 304 else random.randrange(300, 48_000)
    entrees.append((t, ligne(random.choice(visiteurs), t, "GET", p, statut, taille, random.choice(navigateurs))))

for _ in range(240):
    t = debut_panne + timedelta(seconds=random.randrange(int((fin_panne - debut_panne).total_seconds())))
    entrees.append((t, ligne(random.choice(visiteurs), t, "GET", "/api/scores", 500, 21, random.choice(navigateurs))))

for i in range(3_000):
    t = jour.replace(hour=3) + timedelta(seconds=i * 1.2)
    entrees.append((t, ligne(ROBOT, t, "GET", f"/profil?id={i}", 200, random.randrange(900, 4000),
                             "python-requests/2.32.3")))

for _ in range(150):
    t = jour + timedelta(seconds=random.randrange(86_400))
    chemin = random.choice(["/wp-login.php", "/.env", "/admin", "/phpmyadmin/", "/.git/config", "/xmlrpc.php"])
    entrees.append((t, ligne(random.choice(SCANNERS), t, random.choice(["GET", "POST"]), chemin, 404, 153,
                             "Mozilla/5.0 zgrab/0.x")))

entrees.sort(key=lambda e: e[0])
ecrire(HOME / "logs" / "site" / "access.log", "\n".join(l for _, l in entrees) + "\n")

ecrire(M / "2-logs.txt", """\
--- 2. Le site a eu une panne ----------------------------------------

Hier, des joueurs se sont plaints : le classement ne marchait plus.
Le journal du serveur web est dans ~/logs/site/access.log.
Chaque ligne = une visite : IP, date, page demandée, code de réponse
(200 = OK, 404 = page introuvable, 500 = le serveur a planté).

Le fichier est bien trop long pour être lu en entier.

  Combien de lignes ?                     wc -l ~/logs/site/access.log
  Garder les lignes qui contiennent… :    grep '" 500 ' ~/logs/site/access.log

Le  |  envoie la sortie d'une commande dans la suivante :
  Combien d'erreurs 500 ?                 grep '" 500 ' ~/logs/site/access.log | wc -l
  La première (début de la panne) :       grep '" 500 ' ~/logs/site/access.log | head -n 1

  -> Quelle page plantait ? À quelle heure la panne a-t-elle commencé ?

Pour aller plus loin : quelle IP fait le plus de requêtes ?
    cut -d ' ' -f 1 ~/logs/site/access.log | sort | uniq -c | sort -rn | head
""")

ecrire(M / "4-serveur-minecraft.txt", f"""\
--- 4. Lancer ton serveur de jeu -------------------------------------

Un serveur Minecraft, c'est un programme Java. Plutôt que de l'installer
à la main, on le lance dans un conteneur Docker : une boîte qui contient
déjà tout ce qu'il lui faut.

  docker run -d --name jeu -p 25565:25565 -e EULA=TRUE -e TYPE=PAPER \\
    -e VERSION={MC_VERSION} -e MEMORY=1G -e UID=$(id -u) -e GID=$(id -g) \\
    -v ~/jeu:/data --restart unless-stopped itzg/minecraft-server

  Il tourne ?                  docker ps
  Le regarder démarrer :       docker logs -f jeu      (Ctrl+C pour sortir)

Quand tu vois « Done », ouvre l'adresse de ta fiche :  https://jeu-<ton numéro>.<domaine>
Choisis un pseudo et clique sur Connect. Puis va visiter tes voisins !
""")

ecrire(M / "4-serveur-classicube.txt", """\
--- 4. Lancer ton serveur de jeu -------------------------------------

Le serveur de jeu est un programme. Plutôt que de l'installer à la main,
on le lance dans un conteneur Docker : une boîte qui contient déjà tout
ce qu'il lui faut.

  docker run -dit --name jeu --user $(id -u):$(id -g) -p 25565:25565 \\
    -v ~/jeu:/data --restart unless-stopped tuxae/mcgalaxy

  Il tourne ?                  docker ps
  Le regarder démarrer :       docker logs -f jeu      (Ctrl+C pour sortir)

Puis ouvre l'adresse de ta fiche :  https://jeu.<domaine>/?serveur=<ton numéro>
""")

ecrire(M / "5-config-minecraft.txt", """\
--- 5. Le personnaliser ----------------------------------------------

La configuration du serveur est un simple fichier texte :
    nano ~/jeu/server.properties
Change le message d'accueil (ligne  motd=...), par exemple :  motd=Le serveur de Zoe
Ctrl+O pour enregistrer, Entrée, Ctrl+X pour sortir. Puis redémarre :
    docker restart jeu
Le nouveau nom s'affiche dans la liste des serveurs du jeu.

Ce que le serveur raconte :     docker logs jeu | grep joined
Devenir administrateur :        docker exec jeu rcon-cli op <ton pseudo>
""")

ecrire(M / "5-config-classicube.txt", """\
--- 5. Le personnaliser ----------------------------------------------

La configuration du serveur est un simple fichier texte :
    nano ~/jeu/properties/server.properties
Change le message d'accueil (ligne  motd = ...).
Ctrl+O pour enregistrer, Entrée, Ctrl+X pour sortir. Puis redémarre :
    docker restart jeu

Devenir administrateur : connecte-toi une fois au jeu, puis
    docker attach jeu          tape   /setrank <ton pseudo> admin
et détache-toi SANS l'arrêter :  Ctrl+P puis Ctrl+Q
""")

ecrire(M / "bonus-securite.txt", """\
--- Bonus : qui frappe à la porte ? -------------------------------

Ta machine a une adresse IP publique. Depuis qu'elle existe, des robots
du monde entier essaient de deviner le mot de passe pour y entrer (SSH).

  Combien de tentatives ratées ?
      sudo grep "Failed password" /var/log/auth.log | wc -l
  Quels noms d'utilisateur essaient-ils ?
      sudo grep "Invalid user" /var/log/auth.log | head
  Qui a déjà été banni par fail2ban ?
      sudo fail2ban-client status sshd

Et ton terminal web ou ton jeu ? Ils ne sont joignables QUE par la régie :
le pare-feu de la machine bloque tout le reste. Regarde-le :
      sudo nft list ruleset
""")

print(f"Missions générées dans {M}")
