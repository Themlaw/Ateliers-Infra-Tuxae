# Infrastructure de l'atelier

Une VM régie (Traefik, mur de progression, Grafana, client de jeu web) et une VM par participant, sur OVH Public Cloud, DNS chez Cloudflare.

- `packer/` : image des postes
- `regie/`, `postes/` : OpenTofu
- `ansible/` : configuration de la régie et des routes
- `mcgalaxy/` : serveur ClassiCube

```bash
cp config.tfvars.example config.tfvars   # à remplir
make image
make regie
make jourj N=25
make detruire
```
