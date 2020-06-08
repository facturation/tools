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

Le sous-repertoire docker contient un fichier pour docker permettant d'exécuter le script de téléchargement via Docker, notamment pour les utilisateurs sous Windows qui n'ont pas accès en standard à ruby.
