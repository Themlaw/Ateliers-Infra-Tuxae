
VARS  := $(abspath config.tfvars)
DNS_PUBLIC ?= $(shell command -v docker >/dev/null 2>&1 && echo 1)
ifeq ($(DNS_PUBLIC),1)
TOFU  ?= $(CURDIR)/outils/tofu-dns-public
else
TOFU  ?= tofu
endif
export TOFU
NVAR  := $(if $(N),-var nb_postes=$(N),)

.PHONY: verif image regie regie-infra regie-config jourj postes routes plus detruire etat tout-detruire

verif:
	@test -f $(VARS) || (echo "Il manque config.tfvars : cp config.tfvars.example config.tfvars" && exit 1)

PACKER_VARS := packer/config.auto.pkrvars.hcl

image: verif
	grep -E '^(os_auth_url|os_username|os_password|os_project_id|os_region|os_ext_net_name|os_ext_net_id|image_base_name|image_poste_name|packer_flavor|minecraft_version) *=' $(VARS) > $(PACKER_VARS)
	cd packer && bash construire.sh $(VARS)

regie: regie-infra regie-config

regie-infra: verif
	cd regie && $(TOFU) init -upgrade && $(TOFU) apply -var-file=$(VARS)

regie-config:
	cd ansible && ansible-playbook regie.yml

jourj: postes
	cd ansible && ansible-playbook routes.yml -e reset_mur=true
	@echo "Identifiants : identifiants.csv et fiches.html (à imprimer, pas à projeter)"

postes: verif
	cd postes && $(TOFU) init -upgrade && python3 appliquer.py -var-file=$(VARS) $(NVAR)

routes:
	cd ansible && ansible-playbook routes.yml

plus: postes routes

detruire: verif
	cd postes && $(TOFU) destroy -var-file=$(VARS) $(NVAR)
	rm -f postes/regions.auto.tfvars.json
	cd ansible && ansible-playbook routes.yml -e vider=true
	rm -f identifiants.csv mots-de-passe.csv fiches.html

etat:
	cd postes && $(TOFU) output postes

tout-detruire: detruire
	cd regie && $(TOFU) destroy -var-file=$(VARS)
	python3 packer/supprimer_images.py $(VARS)
