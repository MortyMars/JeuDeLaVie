# Le jeu de la vie

Le jeu de la vie, développé en C++ et SFML 3


## Apports de la version

- C'est une version C++ s'appuyant sur la bibliothèque graphique SFML3
- Les exécutables produits sont totalement autonomes, la bibliothèque SFML se trouvant intégrée à l'application (macOS) ou au pack de déploiement (Windows)

- Le jeu démarre en pseudo mode plein écran, pour un spectacle maximum 😉
- Pour disposer d'un plus grand nombre de cellules il est possible de réduire encore leur taille
- La génération des cellules n'est ni automatique ni totalement aléatoire
- C'est au joueur de dessiner des motifs ou d'insèrer des modèles prédéfinis *(Planeur, LWSS, ou Canon)*



## Mode d'emploi rapide

#### Pour jouer :

- **Clic gauche** sur une case la rend vivante (noire)
- **Clic droit** sur une case la rend morte (blanche)

- **'Espace'** démarrer /mettre en pause  *(le titre de la fenêtre indique '**RUNNING**' ou '**EN PAUSE**')*

- **'P'**  Insérer sous le pointeur de la souris, un '*Planeur*' à déplacement aléatoire
- **'L'**  Insérer sous le pointeur de la souris, un '*LWSS*' (LightWeight SpaceShip) à déplacement aléatoire
- **'C'**  Insérer à la droite du pointeur de la souris, un '*Canon à planeurs*' *(à déplacements orientés SE)*
- **'E'**  Tout effacer (rendre toute les cases mortes)
- **'R'**  Stopper le jeu et effacer tout

- **'Échap'**  Quitter 


#### Pour compiler le programme :

- Se reporter au fichier '***CONFIG.md***' qui décrit le processus de compilation et de déploiement pour macOS et Windows.


