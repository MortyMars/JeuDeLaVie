@echo off
REM ============================================================================
REM  compile.bat  -  Compilation Windows du programme
REM ============================================================================
REM
REM  A QUOI SERT CE SCRIPT ?
REM  -----------------------
REM  1) Il compile le programme (comme le ferait Qt Creator) a l'aide de CMake,
REM     dans le dossier 'build\'.
REM  2) Il lance le script 'pack_windows.ps1' qui assemble le dossier autonome
REM     'dist\JeuDeLaVie\' (executable + DLL SFML + runtime), pret a etre
REM     envoye tel quel et a fonctionner SANS RIEN INSTALLER sur le PC cible.
REM
REM  COMMENT L'UTILISER ?
REM  --------------------
REM  Dans PowerShell, depuis le dossier du projet :
REM        .\compile.bat
REM
REM  PREREQUIS (a installer une seule fois sur la machine de compilation) :
REM  - vcpkg (https://vcpkg.io) avec la variable VCPKG_ROOT positionnee,
REM  - puis :  vcpkg install sfml:x64-windows
REM
REM  NB : les lignes commencant par REM sont des commentaires (ignores).
REM ============================================================================

REM On se place dans le dossier du projet, ou que l'on soit.
cd /d "%~dp0"

echo =============================================================
echo  1/2 COMPILATION DU PROGRAMME (dossier build\)
echo =============================================================

REM ---- Verification de la presence de vcpkg (obligatoire pour trouver SFML) ----
if "%VCPKG_ROOT%"=="" (
    echo.
    echo ERREUR : la variable VCPKG_ROOT n'est pas definie.
    echo Installez vcpkg puis positionnez la variable :
    echo    setx VCPKG_ROOT "C:\dev\vcpkg"
    echo puis relancez ce script dans une NOUVELLE fenetre.
    pause
    exit /b 1
)
if not exist "%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" (
    echo.
    echo ERREUR : introuvable : %VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake
    echo Verifiez le chemin d'installation de vcpkg.
    pause
    exit /b 1
)

REM ---- Configuration du projet avec CMake (ne recompile que ce qui change) ----
REM Le "toolchain file" de vcpkg indique a CMake ou trouver SFML.
cmake -B build -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" ^
      -DVCPKG_TARGET_TRIPLET=x64-windows
if errorlevel 1 goto :echec

REM ---- Compilation proprement dite ----
cmake --build build --config Release
if errorlevel 1 goto :echec

echo.
echo Compilation reussie. Assemblage du dossier autonome...
echo.

REM ============================================================================
REM  2/2 EMPAQUETAGE : appel du script PowerShell qui fabrique le dossier
REM      autonome 'dist\JeuDeLaVie\'.
REM ============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File pack_windows.ps1
if errorlevel 1 goto :echec

pause
exit /b 0

:echec
echo.
echo ERREUR lors de la compilation. Corrigez les messages ci-dessus.
pause
exit /b 1
