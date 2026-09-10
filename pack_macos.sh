#!/bin/bash
# ============================================================================
#  pack_macos.sh  -  Création d'une application macOS AUTONOME
# ============================================================================
#
#  À QUOI SERT CE SCRIPT ?
#  ----------------------
#  Après compilation, l'exécutable 'JeuDeLaVie' ne peut pas encore être donné
#  tel quel à n'importe qui : il "pointe" vers les bibliothèques SFML installées
#  par Homebrew sur CETTE machine (dossier /opt/homebrew/...).
#  Un autre Mac, sans Homebrew ni SFML, ne pourrait pas le lancer.
#
#  Ce script règle le problème en fabriquant une véritable application macOS :
#
#        dist/JeuDeLaVie.app
#        ├── Contents/
#        │   ├── Info.plist          (carte d'identité de l'application)
#        │   ├── MacOS/
#        │   │   └── JeuDeLaVie      (l'exécutable lui-même)
#        │   └── Frameworks/
#        │       └── libsfml-*.dylib (TOUTES les bibliothèques SFML + leurs
#        │                            dépendances, copiées à l'intérieur)
#        └── ...
#
#  Toutes les bibliothèques nécessaires étant EMBARQUÉES dans le .app,
#  l'application fonctionne sur n'importe quel Mac, sans rien installer.
#  Le script fabrique aussi un fichier 'dist/JeuDeLaVie-macOS.zip' prêt à
#  être envoyé par e-mail, clé USB, etc.
#
#  COMMENT L'UTILISER ?
#  --------------------
#  Normalement, inutile de l'appeler à la main : il est lancé automatiquement
#  à la fin de 'compile.sh'. On peut aussi le lancer seul :
#
#        bash pack_macos.sh          (après une compilation dans 'build/')
#
# ============================================================================

# 'set -e' arrête le script dès qu'une commande échoue.
# (Les lignes qui commencent par '#' sont des commentaires, ignorées par bash.)
set -e

# ----------------------------------------------------------------------------
# 1) RÉCUPÉRATION DU DOSSIER DU PROJET ET RÉGLAGES DE BASE
# ----------------------------------------------------------------------------
# 'dirname "$0"' = dossier contenant CE script (= le dossier du projet).
# On s'y déplace pour que toutes les commandes suivantes partent du bon endroit,
# quel que soit le dossier depuis lequel on a lancé le script.
cd "$(dirname "$0")"

APP_NAME="JeuDeLaVie"
BUILD_DIR="${1:-build}"                # dossier de compilation (défaut : build)
DIST_DIR="dist"                        # dossier où l'on range le .app final
FRAMEWORKS_DIR="$DIST_DIR/$APP_NAME.app/Contents/Frameworks"   # dossier des bibliothèques

# L'exécutable fabriqué par CMake se trouve dans le dossier de compilation.
EXECUTABLE="$BUILD_DIR/$APP_NAME"

# ----------------------------------------------------------------------------
# 2) VÉRIFICATIONS PRÉALABLES
# ----------------------------------------------------------------------------
# On vérifie que l'exécutable a bien été compilé AVANT de continuer.
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERREUR : exécutable introuvable dans '$BUILD_DIR'."
    echo "Lancez d'abord la compilation :  sh compile.sh   (ou build dans Qt Creator)."
    exit 1
fi

# 'install_name_tool' et 'otool' sont des outils fournis par Apple avec Xcode
# (les "Command Line Tools"). On vérifie qu'ils sont disponibles.
command -v install_name_tool >/dev/null 2>&1 || { echo "ERREUR : install_name_tool introuvable. Installez les Command Line Tools d'Apple (xcode-select --install)."; exit 1; }
command -v otool            >/dev/null 2>&1 || { echo "ERREUR : otool introuvable. Installez les Command Line Tools d'Apple (xcode-select --install)."; exit 1; }

# ----------------------------------------------------------------------------
# 3) CRÉATION DE L'ARBORESCENCE DE L'APPLICATION .app
# ----------------------------------------------------------------------------
# On efface une éventuelle version précédente pour repartir de zéro.
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$FRAMEWORKS_DIR"
mkdir -p "$DIST_DIR/$APP_NAME.app/Contents/Resources"

# ----------------------------------------------------------------------------
# 4) CARTE D'IDENTITÉ DE L'APPLICATION (Info.plist)
# ----------------------------------------------------------------------------
# Ce petit fichier XML dit à macOS que ce dossier est une application à part
# entière (double-cliquable dans le Finder, avec sa propre fenêtre, etc.).
cat > "$DIST_DIR/$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>             <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>      <string>Le Jeu de la Vie</string>
    <key>CFBundleIdentifier</key>       <string>local.$APP_NAME</string>
    <key>CFBundleVersion</key>          <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleExecutable</key>       <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>      <string>APPL</string>
    <key>LSMinimumSystemVersion</key>   <string>11.0</string>
    <key>NSHighResolutionCapable</key>  <true/>
    <key>NSPrincipalClass</key>         <string>NSApplication</string>
</dict>
</plist>
EOF

# ----------------------------------------------------------------------------
# 5) COPIE DE L'EXÉCUTABLE DANS LE .app
# ----------------------------------------------------------------------------
cp "$EXECUTABLE" "$DIST_DIR/$APP_NAME.app/Contents/MacOS/"

# ----------------------------------------------------------------------------
# 6) DÉCOUVERTE ET COPIE DE TOUTES LES BIBLIOTHÈQUES NÉCESSAIRES
# ----------------------------------------------------------------------------
# L'exécutable a besoin de bibliothèques SFML (et de leurs propres dépendances,
# comme 'freetype' pour le dessin des textes). On va :
#   a) demander à l'outil 'otool' la liste des bibliothèques utilisées,
#   b) ne garder que celles qui viennent de Homebrew (/opt/homebrew, /usr/local)
#      -> les bibliothèques du système macOS (/usr/lib, /System/Library) sont
#         déjà présentes sur tous les Mac, inutile de les copier,
#   c) copier chacune dans le dossier Frameworks du .app.

# Dossiers "non système" où peuvent se trouver des bibliothèques à embarquer.
LIB_PREFIXES="/opt/homebrew /usr/local /opt/local"

# Fonction : copie dans Frameworks toutes les bibliothèques non-système dont
# dépend le fichier passé en argument ($1).
# NB : la liste des dépendances est obtenue avec 'otool -L' ; chaque ligne est
# de la forme "  /chemin/vers/bibliotheque.dylib (version...)" : on en extrait
# le chemin (1re colonne) grâce à 'awk'.
scan_libraries() {
    local FILE="$1"
    otool -L "$FILE" | tail -n +2 | while read -r LINE; do
        local LIB
        LIB=$(echo "$LINE" | awk '{print $1}')

        # On ignore les bibliothèques du système macOS (déjà présentes partout).
        local KEEP=0
        for PREFIX in $LIB_PREFIXES; do
            case "$LIB" in
                "$PREFIX"/*) KEEP=1 ;;
            esac
        done
        [ "$KEEP" = "0" ] && continue

        # Copie de la bibliothèque (si elle n'a pas déjà été copiée).
        local BASE
        BASE=$(basename "$LIB")
        if [ ! -f "$FRAMEWORKS_DIR/$BASE" ]; then
            echo "   -> copie de : $LIB"
            cp "$LIB" "$FRAMEWORKS_DIR/$BASE"
        fi
    done
}

echo "Recherche des bibliothèques nécessaires..."
echo "  Exécutable : $EXECUTABLE"

# On répète l'analyse jusqu'à ce que plus aucune nouvelle bibliothèque n'apparaisse :
# en effet, une bibliothèque copiée peut elle-même dépendre d'une autre
# (ex. : sfml-graphics -> freetype -> libpng). En quelques passages, tout est trouvé.
CHANGED=1
while [ "$CHANGED" -eq 1 ]; do
    CHANGED=0
    NB_BEFORE=$(ls "$FRAMEWORKS_DIR" | wc -l | tr -d ' ')
    scan_libraries "$DIST_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    for LIB in "$FRAMEWORKS_DIR"/*.dylib; do
        [ -f "$LIB" ] && scan_libraries "$LIB"
    done
    NB_AFTER=$(ls "$FRAMEWORKS_DIR" | wc -l | tr -d ' ')
    [ "$NB_AFTER" -ne "$NB_BEFORE" ] && CHANGED=1
done

# ----------------------------------------------------------------------------
# 7) RÉPARATION DES CHEMINS DANS L'EXÉCUTABLE ET LES BIBLIOTHÈQUES
# ----------------------------------------------------------------------------
# L'exécutable et les bibliothèques contiennent des chemins du type
# '/opt/homebrew/opt/sfml/lib/libsfml-graphics.3.0.dylib'.
# Sur un autre Mac, ce dossier n'existe pas !
# 'install_name_tool -change' remplace ces chemins par '@executable_path/../Frameworks/...'
# qui pointe vers les bibliothèques EMBARQUÉES dans le .app.

echo "Réparation des chemins de recherche des bibliothèques..."

# Fonction : remplace, dans le fichier $1, la référence vers la bibliothèque $2
# (recherchée par son nom dans la liste 'otool -L') par le nouveau chemin interne.
fix_reference() {
    local FILE="$1"
    local BASE="$2"
    # On cherche l'ancien chemin complet utilisé par le fichier pour cette bibliothèque.
    local OLD_PATH
    OLD_PATH=$(otool -L "$FILE" | awk -v lib="$BASE" '$1 ~ lib {print $1; exit}')
    if [ -n "$OLD_PATH" ]; then
        install_name_tool -change "$OLD_PATH" "@executable_path/../Frameworks/$BASE" "$FILE"
    fi
}

# 7a) L'exécutable principal.
TARGET="$DIST_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
for LIB in "$FRAMEWORKS_DIR"/*.dylib; do
    [ -f "$LIB" ] && fix_reference "$TARGET" "$(basename "$LIB")"
done

# 7b) Chaque bibliothèque embarquée (elles peuvent dépendre les unes des autres :
#     sfml-graphics dépend de sfml-window, etc.).
for LIB in "$FRAMEWORKS_DIR"/*.dylib; do
    [ -f "$LIB" ] || continue
    BASE=$(basename "$LIB")
    # On remplace d'abord le "nom interne" de la bibliothèque ('otool -D').
    install_name_tool -id "@executable_path/../Frameworks/$BASE" "$LIB"
    # Puis toutes ses références vers les autres bibliothèques embarquées.
    for OTHER in "$FRAMEWORKS_DIR"/*.dylib; do
        [ -f "$OTHER" ] && fix_reference "$LIB" "$(basename "$OTHER")"
    done
done

# 7c) On retire les éventuels "chemins de recherche" (rpath) vers Homebrew : ils
#     ne servent plus à rien puisque tout est embarqué. '|| true' évite un arrêt
#     du script si aucun rpath de ce type n'existe.
for PREFIX in $LIB_PREFIXES; do
    RPATH=$(otool -l "$TARGET" | awk -v p="$PREFIX" '/LC_RPATH/{getline; getline; if ($0 ~ p) print $2}')
    if [ -n "$RPATH" ]; then
        install_name_tool -delete_rpath "$RPATH" "$TARGET" 2>/dev/null || true
    fi
done

# ----------------------------------------------------------------------------
# 8) VÉRIFICATION FINALE DES LIENS
# ----------------------------------------------------------------------------
# Petit contrôle visuel : toutes les références doivent désormais pointer vers
# '@executable_path/../Frameworks/...' ou vers le système macOS.
echo ""
echo "Liens de l'exécutable après réparation :"
otool -L "$TARGET"

# ----------------------------------------------------------------------------
# 9) SIGNATURE "AD HOC" DE L'APPLICATION
# ----------------------------------------------------------------------------
# Depuis macOS 11 (et obligatoirement sur les Mac Apple Silicon), tout logiciel
# doit être signé, même un simple programme personnel. Sans compte développeur
# Apple, on utilise une signature "ad hoc" ('-s -') qui rend l'application
# exécutable sur la machine qui l'a compilée et sur les autres Mac (avec, au
# pire, un clic droit > Ouvrir la première fois, voir le README).
echo ""
echo "Signature de l'application (ad hoc)..."
# 1) On signe d'abord chaque bibliothèque embarquée (obligatoire en arm64).
for LIB in "$FRAMEWORKS_DIR"/*.dylib; do
    [ -f "$LIB" ] && codesign --force -s - "$LIB"
done
# 2) Puis on signe l'application elle-même (ceci signe aussi l'exécutable).
codesign --force -s - "$DIST_DIR/$APP_NAME.app"

# ----------------------------------------------------------------------------
# 10) COMPRESSION DANS UNE ARCHIVE .zip PRÊTE À DISTRIBUER
# ----------------------------------------------------------------------------
echo "Création de l'archive zip..."
ditto -c -k --sequesterRsrc --keepParent \
    "$DIST_DIR/$APP_NAME.app" \
    "$DIST_DIR/$APP_NAME-macOS.zip"

echo ""
echo "============================================================="
echo " TERMINÉ ! Application autonome créée dans :"
echo "   $DIST_DIR/$APP_NAME.app"
echo ""
echo " Archive à distribuer (à envoyer par e-mail, clé USB...) :"
echo "   $DIST_DIR/$APP_NAME-macOS.zip"
echo ""
echo " Sur un autre Mac : dézipper puis double-cliquer sur"
echo " 'JeuDeLaVie.app'. Aucune installation n'est nécessaire."
echo "============================================================="
