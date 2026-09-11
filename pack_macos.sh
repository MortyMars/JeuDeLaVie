#!/bin/bash
# ============================================================================
#  pack_macos.sh  -  Création d'une application macOS AUTONOME & UNIVERSELLE
# ============================================================================

# 'set -e' arrête le script dès qu'une commande échoue.
set -e

# ----------------------------------------------------------------------------
# 1) RÉCUPÉRATION DU DOSSIER DU PROJET ET RÉGLAGES DE BASE
# ----------------------------------------------------------------------------
cd "$(dirname "$0")"

APP_NAME="JeuDeLaVie"
BUILD_DIR="${1:-build}"                # dossier de compilation (défaut : build)
DIST_DIR="dist"                        # dossier où l'on range le .app final
FRAMEWORKS_DIR="$DIST_DIR/$APP_NAME.app/Contents/Frameworks"   # dossier des bibliothèques

# Chemins vers nos bibliothèques embarquées dans le dépôt GitHub
SILICON_LOCAL_DIR="$(pwd)/dependencies/sfml-macos/silicon/lib"
INTEL_LOCAL_DIR="$(pwd)/dependencies/sfml-macos/intel/lib"

# L'exécutable fabriqué par CMake se trouve dans le dossier de compilation.
EXECUTABLE="$BUILD_DIR/$APP_NAME"

# ----------------------------------------------------------------------------
# 2) VÉRIFICATIONS PRÉALABLES
# ----------------------------------------------------------------------------
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERREUR : exécutable introuvable dans '$BUILD_DIR'."
    echo "Lancez d'abord la compilation :  sh compile.sh"
    exit 1
fi

command -v install_name_tool >/dev/null 2>&1 || { echo "ERREUR : install_name_tool introuvable. Installez les Command Line Tools (xcode-select --install)."; exit 1; }
command -v otool            >/dev/null 2>&1 || { echo "ERREUR : otool introuvable. Installez les Command Line Tools (xcode-select --install)."; exit 1; }

# ----------------------------------------------------------------------------
# 3) CRÉATION DE L'ARBORESCENCE DE L'APPLICATION .app
# ----------------------------------------------------------------------------
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$FRAMEWORKS_DIR/arm64"
mkdir -p "$FRAMEWORKS_DIR/x86_64"
mkdir -p "$DIST_DIR/$APP_NAME.app/Contents/Resources"

# ----------------------------------------------------------------------------
# 4) CARTE D'IDENTITÉ DE L'APPLICATION (Info.plist)
# ----------------------------------------------------------------------------
cat > "$DIST_DIR/$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://apple.com">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>             <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>      <string>Le Jeu de la Vie</string>
    <key>CFBundleIdentifier</key>       <string>local.$APP_NAME</string>
    <key>CFBundleVersion</key>          <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key>       <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>      <string>APPL</string>
    <key>LSMinimumSystemVersion</key>   <string>11.0</string>
    <key>NSHighResolutionCapable</key>  <true/>
</dict>
</plist>
EOF

# ----------------------------------------------------------------------------
# 5) COPIE DE L'EXÉCUTABLE DANS LE .app
# ----------------------------------------------------------------------------
cp "$EXECUTABLE" "$DIST_DIR/$APP_NAME.app/Contents/MacOS/"
TARGET="$DIST_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"

# ----------------------------------------------------------------------------
# 6) DÉPLOIMENT DES BIBLIOTHÈQUES PAR ARCHITECTURE
# ----------------------------------------------------------------------------
echo "Déploiement des bibliothèques par architecture..."
cp "$SILICON_LOCAL_DIR"/*.dylib "$FRAMEWORKS_DIR/arm64/" 2>/dev/null || true
cp "$INTEL_LOCAL_DIR"/*.dylib "$FRAMEWORKS_DIR/x86_64/" 2>/dev/null || true

# ----------------------------------------------------------------------------
# 7) RÉPARATION DES CHEMINS D'ACCÈS INTERNES
# ----------------------------------------------------------------------------
echo "Réparation des chemins d'accès internes..."

# 7a) Traitement de la partie ARM64 (Silicon)
OLD_PATHS_ARM=$(otool -arch arm64 -L "$TARGET" 2>/dev/null | awk '/libsfml/{print $1}')
for OLD_PATH in $OLD_PATHS_ARM; do
    if [ -n "$OLD_PATH" ]; then
        BASE=$(basename "$OLD_PATH")
        install_name_tool -arch arm64 -change "$OLD_PATH" "@executable_path/../Frameworks/arm64/$BASE" "$TARGET" 2>/dev/null || true
    fi
done

# 7b) Traitement de la partie X86_64 (Intel)
OLD_PATHS_INTEL=$(otool -arch x86_64 -L "$TARGET" 2>/dev/null | awk '/libsfml/{print $1}')
for OLD_PATH in $OLD_PATHS_INTEL; do
    if [ -n "$OLD_PATH" ]; then
        BASE=$(basename "$OLD_PATH")
        install_name_tool -arch x86_64 -change "$OLD_PATH" "@executable_path/../Frameworks/x86_64/$BASE" "$TARGET" 2>/dev/null || true
    fi
done

# 7c) Correction de l'identité interne des dylibs copiées
if [ -d "$FRAMEWORKS_DIR/arm64" ]; then
    for LIB in "$FRAMEWORKS_DIR/arm64"/*.dylib; do
        if [ -f "$LIB" ]; then
            install_name_tool -id "@executable_path/../Frameworks/arm64/$(basename "$LIB")" "$LIB" 2>/dev/null || true
        fi
    done
fi

if [ -d "$FRAMEWORKS_DIR/x86_64" ]; then
    for LIB in "$FRAMEWORKS_DIR/x86_64"/*.dylib; do
        if [ -f "$LIB" ]; then
            install_name_tool -id "@executable_path/../Frameworks/x86_64/$(basename "$LIB")" "$LIB" 2>/dev/null || true
        fi
    done
fi

# ----------------------------------------------------------------------------
# 8) SIGNATURE "AD HOC" DE L'APPLICATION
# ----------------------------------------------------------------------------
echo "Signature universelle de l'application (ad hoc)..."

# On désactive l'arrêt immédiat pour la signature par sécurité
set +e

if [ -d "$FRAMEWORKS_DIR/arm64" ]; then
    for LIB in "$FRAMEWORKS_DIR/arm64"/*.dylib; do
        [ -f "$LIB" ] && codesign --force -s - "$LIB" >/dev/null 2>&1
    done
fi

if [ -d "$FRAMEWORKS_DIR/x86_64" ]; then
    for LIB in "$FRAMEWORKS_DIR/x86_64"/*.dylib; do
        [ -f "$LIB" ] && codesign --force -s - "$LIB" >/dev/null 2>&1
    done
fi

if [ -f "$TARGET" ]; then
    codesign --force -s - "$TARGET" >/dev/null 2>&1
fi

codesign --force -s - "$DIST_DIR/$APP_NAME.app" >/dev/null 2>&1

# On réactive l'arrêt sur erreur pour l'étape finale du ZIP
set -e

# ----------------------------------------------------------------------------
# 9) COMPRESSION DANS UNE ARCHIVE .zip
# ----------------------------------------------------------------------------
echo "Création de l'archive zip..."

rm -f "$DIST_DIR/$APP_NAME-macOS.zip"
ZIP_OUTPUT_PATH="$(pwd)/$DIST_DIR/$APP_NAME-macOS.zip"

cd "$DIST_DIR"
ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$ZIP_OUTPUT_PATH"
cd ..

echo ""
echo "============================================================="
echo " TERMINÉ ! L'application autonome et universelle a été créée."
echo " Fichier ZIP généré avec succès dans :"
echo "   $DIST_DIR/$APP_NAME-macOS.zip"
echo "============================================================="




