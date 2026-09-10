# Le Jeu de la Vie

Le jeu de la vie en C++ et **SFML 3**.

> **Ce projet est un projet CMake pur, compilable au choix :**
> - dans **Qt Creator** (menu *Ouvrir* -> choisir `CMakeLists.txt`), pour l'aspect pratique et visuel
> - en **ligne de commande** (Terminal macOS / PowerShell Windows), pour compiler **et** déployer

## Objectif : des exécutables autonomes sur macOS et Windows

Le programme utilise SFML uniquement **au moment de la compilation**.
Les scripts d'empaquetage fournis, copient la bibliothèque SFML (et ses dépendances) **à l'intérieur 
du dossier distribué**. Un destinataire du programme n'a **rien à installer** *(unzip & clic)*.

| Système  | Fichier produit par les scripts                     | À distribuer                    |
|----------|-----------------------------------------------------|---------------------------------|
| macOS    | `dist/JeuDeLaVie.app` (application autonome)        | `dist/JeuDeLaVie-macOS.zip`     |
| Windows  | `dist/JeuDeLaVie\` (exe + DLL à côté)               | `dist/JeuDeLaVie-Windows.zip`   |

---

## Compilation sur macOS

### Prérequis (une seule fois)

1. **Xcode Command Line Tools** : dans le Terminal,
   `xcode-select --install`
2. **Homebrew** : https://brew.sh
3. **SFML 3** : dans le Terminal, `brew install sfml`

### Compiler et empaqueter (méthode simple)

Dans le Terminal, depuis le dossier du projet :

```bash
sh compile.sh
```

Cette commande compile le programme puis crée automatiquement :

- `dist/JeuDeLaVie.app` : l'application autonome (testable en double-cliquant),
- `dist/JeuDeLaVie-macOS.zip` : l'archive à envoyer.

### Compiler dans Qt Creator (méthode alternative)

1. Lancer Qt Creator, menu **Fichier > Ouvrir un fichier ou projet**,
2. choisir `CMakeLists.txt` du projet,
3. cliquer sur le bouton **Build** (marteau). Rien d'autre n'est à configurer,
   le projet est volontairement **indépendant de Qt**.

> Pour produire l'application autonome après un build Qt Creator, lancer dans
> le Terminal : `sh pack_macos.sh` (ou `sh pack_macos.sh build` si le
> dossier de compilation s'appelle `build`).

### Faire tourner l'application sur un autre Mac

1. Transmettre `dist/JeuDeLaVie-macOS.zip` (e-mail, clé USB...),
2. sur le Mac destinataire : dézipper puis double-cliquer sur `JeuDeLaVie.app`.

>**Premier lancement (Gatekeeper)** : l'application n'étant pas signée par Apple,
macOS peut afficher *« JeuDeLaVie ne peut pas être ouvert »*. Il suffit alors de
faire un **clic droit** sur `JeuDeLaVie.app` puis choisir **Ouvrir**, et
confirmer. Cette manipulation n'est nécessaire qu'une seule fois.



---

## Compilation sur Windows

### Prérequis (une seule fois)

1. **Visual Studio** (Build Tools ou édition Community) avec la charge de
   travail « Développement Desktop en C++ ».
2. **CMake** : https://cmake.org (cocher « Add CMake to PATH » à l'installation)
3. **vcpkg** : https://vcpkg.io
   ```powershell
   git clone https://github.com/microsoft/vcpkg
   cd vcpkg
   .\bootstrap-vcpkg.bat
   .\vcpkg integrate install
   setx VCPKG_ROOT "C:\chemin\vers\vcpkg"     # adapter le chemin
   ```
4. **SFML 3** (via vcpkg) :
   ```powershell
   vcpkg install sfml:x64-windows
   ```

### Compiler et empaqueter

Dans PowerShell, depuis le dossier du projet :

```powershell
.\compile.bat
```

Cette commande compile le programme puis crée automatiquement :

- `dist\JeuDeLaVie\` : le dossier autonome (exe + DLL SFML + runtime),
- `dist\JeuDeLaVie-Windows.zip` : l'archive à envoyer.

> **Note** : il faut relancer PowerShell après `setx VCPKG_ROOT` pour que la
> variable d'environnement soit prise en compte.

### Compiler dans Qt Creator (méthode alternative, plus avancée)

Qt Creator doit utiliser un kit dont le compilateur correspond à celui des
bibliothèques vcpkg (Visual Studio). Il faut alors ajouter dans le kit le
fichier d'outillage vcpkg :
**Outils > Options > Kits > (kit utilisé) > CMake Configuration** :

```
CMAKE_TOOLCHAIN_FILE:STRING=C:\chemin\vers\vcpkg\scripts\buildsystems\vcpkg.cmake
```

Pour Windows, la méthode recommandée reste `compile.bat` (plus simple).

### Faire tourner le programme sur un autre PC

1. Envoyer `dist\JeuDeLaVie-Windows.zip`,
2. sur le PC destinataire : dézipper puis double-cliquer sur `JeuDeLaVie.exe`.
   Aucune installation n'est nécessaire.

---

## Notes techniques

>- **Architecture des processeurs** : le programme est compilé pour l'architecture de la machine qui compile. Un '.app' compilé sur un Mac Apple Silicon (M1/M2/M3) fonctionne sur les Mac Apple Silicon ; pour des Mac Intel, recompiler le même projet sur un Mac Intel. Même principe sous Windows (x64).
>- La création d'un '*binaire universel*' nécessiterait d'installer SFML en double configuration (Intel + Apple Silicon) sur la machine de compilation. Cette double installation n'est pas prise en charge ici par souci de simplicité.
>- **Qt** ne prend pas part dans la construction du code source : les seuls fichiers nécessaires au programme sont `main.cpp`, `JeuDeLaVie.h`, `JeuDeLaVie.cpp`.
>- Les scripts d'empaquetage sont suffisament commentés (`pack_macos.sh`, `pack_windows.ps1`) pour pouvoir être adaptés facilement.
