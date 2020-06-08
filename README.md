Ce script permet de télécharger tous les devis et factures générés via notre outil, de manière incrémentale.

# Configuration :

copier le fichier config.sample.yml, le remplir avec vos informations d'authentification,
et enregistrer ce fichier sous le nom config.yml

# Usage :
```shell
ruby ./download.rb
```

# Remarques :

* les documents déjà téléchargés ne sont pas retéléchargés
* les factures externes ne peuvent pas être générées par notre outil et donc ne sont pas téléchargeables
* les brouillons ne sont jamais téléchargés


# Docker

Il est possible d'executer ce script via Docker.
La documentation et l'image sont sur [Docker Hub](https://hub.docker.com/repository/docker/facturation/download)
