# Le jeu de la vie

Le jeu de la vie en C++ et SFML 3


## Apports de la version

- C'est une version C++ utilisant la bibliothèque graphique SFML3
- Le jeu démarre en mode plein écran, pour un spectacle maximum 😉
- Pour disposer d'un plus grand nombre de cellules il est possible de réduire encore leur taille
- La génération des cellules n'est ni automatique ni totalement aléatoire
- C'est au joueur de dessiner des motifs ou d'insèrer des modèles prédéfinis *(Planeur, LWSS, ou Canon)*



## Mode d'emploi rapide

#### Avant démarrage :

- **Clic gauche** à la souris sur une case : la rend vivante (noire)
- **Clic droit** à la souris sur une case : la rend morte (blanche)

#### Démarrage du jeu :

- **Touche 'Espace'** du clavier pour démarrer *(le titre de la fenêtre indique alors  '**RUNNING**')*

#### Après démarrage :

- **Touche 'P'** : Insérer sous le pointeur de la souris, un '*Planeur*' à déplacement aléatoire
- **Touche 'L'**  : Insérer sous le pointeur de la souris, un '*LWSS*' (LightWeight SpaceShip) à déplacement aléatoire
- **Touche 'C'** : Insérer à la droite du pointeur de la souris, un '*Canon à planeurs*' *(à déplacements orientés SE)*
- **Touche 'E'** : Tout effacer (rendre toute les cases mortes)
- **Touche 'R'** : Stopper le jeu et effacer tout

#### Mettre en pause :

- **Touche 'Espace'** du clavier pour mettre en pause *(le titre de la fenêtre indique alors  '**EN PAUSE**')*

#### Quitter le jeu

- **Touche 'Échap'** pour quitter 


## Compilation

- La bibliothèque '*SFML3*' doit être pré-installée 
	- **sous macOS** : taper dans le Terminal `'brew install SFML'` ('*homebrew*' doit évidemment être installé)
	- **sous Windows** : taper dans PowerShell `'vcpkg install sfml:x64-windows'`('*vcpkg*' doit être installé)

- Pour compiler le programme,
	- **sous macOS** : utiliser Qt Creator, ou dans le **Terminal** taper`'sh compile.sh'`à partir du dossier du projet
	- **sous Windows** : utiliser Qt Creator, ou dans **PowerShell** taper`'compile.bat'`à partir du dossier du projet

- Pour passer l'étape de compilation, **télécharger** simplement les exécutables proposés pour MacOS et Windows


