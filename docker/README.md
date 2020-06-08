Cette image docker permet d'executer le script de téléchargement sur une machine ne disposant pas de ruby

1) installer Docker Desktop

2) ouvrir une fenêtre de ligne de commande

3) construire l'image
docker build --tag facturation/download .


4) executer le script
docker run --rm -it --name facturation -v `pwd`/downloads:/app/downloads -e FIRM_ID=XXX -e API_ID=YYY -e API_KEY=ZZZ facturation/download