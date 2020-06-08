# Utilisation

Le plus simple est d'utiliser l'image disponible sur [Docker Hub](https://hub.docker.com/repository/docker/facturation/download)

# Personnalisation

Si vous souhaitez utiliser une version personnalisée du script, voici comment executer le fichier Docker présent dans ce répertoire

1) installer [Docker Desktop](https://www.docker.com/products/docker-desktop)

2) ouvrir une fenêtre de ligne de commande

3) construire l'image (après l'avoir personnalisée)
```shell
docker build --tag facturation/download .
```


4) executer le script
```shell
docker run --rm -it --name facturation -v `pwd`/downloads:/app/downloads -e FIRM_ID=XXX -e API_ID=YYY -e API_KEY=ZZZ facturation/download
```
