# ============================================================================
#  JeuDeLaVie  -  CMakeLists.txt
# ============================================================================
#
#  QU'EST-CE QUE CE FICHIER ?
#  -------------------------
#  C'est la "recette de cuisine" qui permet de compiler le programme.
#  Il est lu par l'outil CMake, qui est lui-même utilisé :
#     - par Qt Creator (l'IDE) quand vous ouvrez ce dossier,
#     - ou en ligne de commande (fichiers compile.sh / compile.bat).
#
#  LIBRE DE TOUTE DÉPENDANCE À Qt
#  ------------------------------
#  Le programme ne contient AUCUN appel à la bibliothèque Qt : il utilise
#  uniquement SFML pour la fenêtre graphique. Qt Creator n'est qu'un
#  "éditeur + compilateur" au même titre que la ligne de commande.
#  Résultat : ce fichier fonctionne à l'identique dans Qt Creator,
#  dans le Terminal (macOS) ou dans PowerShell (Windows), sans que Qt
#  ne soit installé.
#
#  DEPENDANCE À SFML : SEULEMENT À LA COMPILATION
#  ----------------------------------------------
#  SFML reste nécessaire pour COMPILER le programme. Mais grâce aux scripts
#  d'empaquetage (pack_macos.sh, pack_windows.bat), les bibliothèques SFML
#  sont copiées À CÔTÉ de l'exécutable distribué : la personne qui reçoit
#  le programme n'a donc RIEN à installer sur son ordinateur.
# ============================================================================


# --- Version minimale de CMake exigée (Qt Creator et CMake 3.16+ le savent) ---
cmake_minimum_required(VERSION 3.16)

# --- Nom du projet + langage utilisé (ici : uniquement du C++) ---------------
# NOTE : on ne déclare QUE le C++. Aucune déclaration 'Qt' ici : le projet
# est volontairement indépendant de Qt, seul SFML est utilisé pour l'affichage.
project(JeuDeLaVie
    LANGUAGES CXX
)

# --- Norme du langage C++ utilisée (C++17) -----------------------------------
# CMAKE_CXX_STANDARD_REQUIRED = ON  ->  le compilateur DOIT accepter C++17,
# sinon la compilation s'arrête avec un message d'erreur clair.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# On désactive les extensions propres au compilateur (g++/clang)
# pour n'utiliser que le C++ standard, identique sur macOS et Windows.
set(CMAKE_CXX_EXTENSIONS OFF)


# --- Choix du mode de compilation par défaut (Release = optimisé) ------------
# En l'absence de mode précisé (ce qui arrive souvent dans Qt Creator),
# on force le mode "Release" : le programme est compilé en version optimisée
# (rapide), sans les symboles de débogage inutiles pour l'utilisateur final.
# 'GENERATOR_IS_MULTI_CONFIG' concerne les générateurs capables de produire
# plusieurs modes à la fois (Xcode, Visual Studio) : dans ce cas on ne force rien.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Mode de compilation" FORCE)
endif()


# =============================================================================
#  RECHERCHE DE SFML 3
# =============================================================================
# SFML est la bibliothèque graphique utilisée pour créer la fenêtre et dessiner
# les cellules. Elle doit être présente pour COMPILER, mais pas pour EXÉCUTER
# le programme une fois empaqueté (voir les scripts de distribution).
#
# 1) On indique à CMake les dossiers "classiques" où SFML peut être installé :
#    - macOS  : Homebrew installe SFML dans /opt/homebrew (Apple Silicon)
#               ou dans /usr/local (Mac Intel).
#    - Windows : le chemin est normalement donné par vcpkg via le "toolchain
#               file" (voir compile.bat). On n'a donc rien à faire ici.
if(APPLE)
    list(APPEND CMAKE_PREFIX_PATH "/opt/homebrew")  # Mac Apple Silicon (M1/M2/M3)
    list(APPEND CMAKE_PREFIX_PATH "/usr/local")     # Mac Intel
endif()

# 2) On demande à CMake de trouver SFML version 3 et ses 3 modules utilisés :
#    Graphics (dessin), Window (fenêtre) et System (types de base).
#    ('QUIET' : on masque les messages d'erreur internes de CMake, pour
#     afficher à la place notre propre message d'aide plus clair ci-dessous.)
find_package(SFML 3 COMPONENTS Graphics Window System QUIET)

# 3) Si SFML n'a pas été trouvé, on arrête la configuration avec des
#    explications destinées à un développeur non professionnel.
if(NOT SFML_FOUND)
    if(APPLE)
        set(_aide_sfml "Installez SFML avec Homebrew :   brew install sfml")
    elseif(WIN32)
        set(_aide_sfml "Installez SFML avec vcpkg :   vcpkg install sfml:x64-windows")
    else()
        set(_aide_sfml "Installez SFML (voir la documentation de votre distribution Linux)")
    endif()
    message(FATAL_ERROR
        "\nSFML 3 (Graphics + Window + System) est introuvable.\n"
        "${_aide_sfml}\n"
        "SFML n'est nécessaire QUE pour compiler : il sera embarqué automatiquement\n"
        "dans l'exécutable distribué par compile.sh / compile.bat.\n"
        "Si SFML est installé ailleurs que dans un dossier standard, indiquez son\n"
        "chemin à CMake en relançant avec :  -DSFML_DIR=/chemin/vers/lib/cmake/SFML\n")
endif()
unset(_aide_sfml)


# =============================================================================
#  DÉFINITION DE L'EXÉCUTABLE
# =============================================================================
# add_executable demande à CMake de compiler un programme (un "exécutable")
# à partir des fichiers sources C++ du projet.
add_executable(JeuDeLaVie
    JeuDeLaVie.h      # en-tête (déclarations) de la logique du jeu
    JeuDeLaVie.cpp    # code de la logique du jeu (règles, dessin des motifs...)
    main.cpp          # programme principal (fenêtre, clavier, souris)
)

# 3) On relie l'exécutable aux modules SFML trouvés plus haut.
#    'PRIVATE' signifie que SFML ne sert qu'à fabriquer l'exécutable,
#    il n'a pas besoin d'être transmis ailleurs.
target_link_libraries(JeuDeLaVie PRIVATE
    SFML::Graphics
    SFML::Window
    SFML::System
)


# =============================================================================
#  RÉGLAGES PROPRES À CHAQUE SYSTÈME
# =============================================================================

# --- macOS : permettre le lancement de la fenêtre en mode natif ---
# Rien de particulier à faire ici : SFML gère lui-même la création de la
# fenêtre Cocoa. L'empaquetage dans une application .app "autonome" est
# réalisé par le script 'pack_macos.sh' (voir compile.sh).

# --- macOS : version minimale du système acceptée ---
# On déclare que le programme est compatible avec macOS 11 (Big Sur) et plus
# récent. Sans cette ligne, le programme exigerait la dernière version de
# macOS en date, ce qui réduirait inutilement le nombre de Mac compatibles.
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "Version minimale de macOS supportée")
endif()


# =============================================================================
#  INSTALLATION DU PROGRAMME (étape FACULTATIVE et avancée)
# =============================================================================
# Permet, si on le souhaite, d'installer l'exécutable dans le système
# (commande 'cmake --install build' ou 'make install').
# La distribution recommandée reste cependant les scripts compile.sh /
# compile.bat qui produisent un dossier ou une application autonome.
if(QNX)
    install(TARGETS JeuDeLaVie
        RUNTIME DESTINATION /tmp/GameOfLife/bin
    )
elseif(UNIX AND NOT ANDROID)
    install(TARGETS JeuDeLaVie
        RUNTIME DESTINATION /opt/GameOfLife/bin
    )
elseif(WIN32)
    install(TARGETS JeuDeLaVie
        RUNTIME DESTINATION bin
    )
endif()
