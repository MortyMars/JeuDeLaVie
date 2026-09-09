# Jeu de la vie C++
Le jeu de la vie en C++

## Quoi de neuf dans cette version ?
- C'est une version C++ utilisant la bibliothèque graphique SFML3
- Le jeu est capable de tourner dans une grande fenêtre sans gréver les performances
- Au démarrage la grille occupe tout l'espace de l'écran
- Noter que pour disposer d'un encore plus grand nombre de cellules il est possible de réduire leur taille
- Le démarrage n'est pas automatique en random : on dessine des motifs ou on insère des modèles prédéfinis
 
## Mode d'emploi rapide
Avant démarrage :
- Clic gauche à la souris sur une case : la rend vivante (noire)
- Clic droit à la souris sur une case : la rend morte (blanche)
Démarrage du jeu :
- Touche 'Espace' du clavier pour démarrer
Après démarrage :
- Touche 'P' : Insérer un 'Planeur' à déplacement aléatoire, sous le pointeur de souris
- Touche 'L' : Insérer un 'LWSS' (le + petit vaisseau) à déplacement aléatoire, sous le pointeur de souris
- Touche 'C' : Insérer un canon à planeurs (orientés SE) à l'emplacement du pointeur de souris
- Touche 'E' du clavier : tout effacer (mettre toute les cases mortes)
- Touche 'R' du clavier : Stoppe le jeu et efface tout
Quitter le jeu
- Touche 'Échap' pour quitter 

## Compilation
- La bibliothèque SFML3 doit être pré-installée 
	- sous macOS 'brew install SFML' ('homebrew' doit évidemment être installé)
	- sous Windows 'vcpkg install sfml:x64-windows' ('vcpkg' doit être installé...)
- Pour compiler le programme,
	- sous macOS : utiliser un IDE (Qt Creator ou VSC), ou lancer dans le Terminal la commande 'sh compile.sh' à partir du dossier du projet
	- sous Windows : utiliser un IDE (Qt Creator ou VSC), ou lancer dans PowerShell la commande 'compile.bat'
- Si la compilation ne vous inspire pas, téléchargez simplement les exécutables proposés pour MacOS et Windows

# Bon jeu !
