# Atelier #1 : Héberger son propre serveur Minecraft ?

## Se connecter

```bash
ssh eleve@poste-NN.atelier.tuxae.fr
```

Ou dans le navigateur : `https://term-NN.atelier.tuxae.fr`

## Lancer le serveur Minecraft

```bash
docker run -d --name jeu -p 25565:25565 -e EULA=TRUE -e TYPE=PAPER \
  -e VERSION=1.20.4 -e MEMORY=1G -e UID=$(id -u) -e GID=$(id -g) \
  -v ~/jeu:/data --restart unless-stopped itzg/minecraft-server
```

| Option | Rôle |
|---|---|
| `-d` | en arrière-plan |
| `--name jeu` | un nom, pour `docker logs jeu` ou `docker restart jeu` |
| `-p 25565:25565` | le port 25565 de la machine mène au conteneur |
| `-e …` | des réglages (licence, serveur, version, mémoire) |
| `-v ~/jeu:/data` | le monde vit dans `~/jeu`, hors du conteneur |
| `--restart unless-stopped` | relancé s'il plante ou au redémarrage |
| `itzg/minecraft-server` | l'image à lancer |

```bash
docker ps              # il tourne ?
docker logs -f jeu     # attendre « Done », Ctrl+C pour sortir
```

## Jouer

`https://jeu.atelier.tuxae.fr`, serveur `poste-NN.atelier.tuxae.fr`

## Configurer

```bash
nano ~/jeu/server.properties     # changer motd=…  (Ctrl+O, Entrée, Ctrl+X)
docker restart jeu
```
