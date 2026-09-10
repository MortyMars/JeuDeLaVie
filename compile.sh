#!/bin/bash
# ============================================================================
#  compile.sh  -  Compilation + création de l'application macOS AUTONOME
# ============================================================================
#
#  À QUOI SERT CE SCRIPT ?
#  ----------------------
#  1) Il compile le programme (comme le ferait Qt Creator) à l'aide de CMake,
#     dans le dossier 'build/'.
#  2) Il lance 'pack_macos.sh' qui fabrique l'application macOS autonome
#     'dist/JeuDeLaVie.app' (SFML embarquée) + l'archive
#     'dist/JeuDeLaVie-macOS.zip', prête à être distribuée
#
#  COMMENT L'UTILISER ?
#  --------------------
#  Dans le Terminal, depuis le dossier du projet :
#        sh compile.sh
#
#  PRÉREQUIS (à installer une seule fois sur la machine de compilation) :
#  - Xcode Command Line Tools  (xcode-select --install)
#  - Homebrew  (https://brew.sh) puis :  brew install sfml cmake
#    (pour installer sfml et cmake simult&nément)
#
# ============================================================================

# On se place dans le dossier du projet, quel que soit l'endroit d'où l'on
# lance le script (double-clic, Terminal dans un autre dossier, etc.).
cd "$(dirname "$0")"

echo "============================================================="
echo " 1/2 COMPILATION DU PROGRAMME (dossier 'build/')"
echo "============================================================="

# Configure le projet avec CMake (ne recompile que ce qui a changé).
# '-B build' = on range tout dans le dossier 'build'.
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Compile réellement le programme.
cmake --build build -j

echo ""
echo "Compilation réussie. Création de l'application autonome..."
echo ""

# ============================================================================
# 2/2) EMPAQUETAGE dans une application macOS autonome (.app)
#      Le script 'pack_macos.sh' copie SFML DANS l'application : le résultat
#      fonctionne sur n'importe quel Mac sans rien installer.
# ============================================================================
echo "============================================================="
echo " 2/2 EMPAQUETAGE DU PROGRAMME (dossier 'dist/')"
echo "============================================================="
bash pack_macos.sh build
