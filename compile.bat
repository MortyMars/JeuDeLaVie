@echo off
REM COMPILATION DU PROGRAMME SOUS WINDOWS
REM
REM Nécessite vcpkg avec SFML installé au préalable :
REM   vcpkg install sfml
REM Et la variable d'environnement VCPKG_ROOT positionnée vers le dossier vcpkg
REM (ou adapte le chemin ci-dessous en dur si tu préfères)

cmake -Bbuild2 -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake
cmake --build build2