# JeuDeLaVie

# CORPS DU PROJET ############################################################################
cmake_minimum_required(VERSION 3.16)

# Langage C++
project(JeuDeLaVie
    LANGUAGES CXX
)

# Norme C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


# Headers Sources et Exécutable
add_executable(JeuDeLaVie
    JeuDeLaVie.h
    JeuDeLaVie.cpp
    main.cpp
)


# CONFIGURATION POUR SFML ####################################################################
# 1. Indiquer à CMake où chercher les packages Homebrew sous macOS
if(APPLE)
    list(APPEND CMAKE_PREFIX_PATH "/opt/homebrew")  # Pour les Mac Apple Silicon
    list(APPEND CMAKE_PREFIX_PATH "/usr/local")     # Pour les Mac Intel
endif()

# 1bis. Indiquer à CMake où chercher le SDK SFML installé manuellement sous Windows
# (inutile si compilation via vcpkg : dans ce cas, le chemin est fourni par le
#  toolchain file vcpkg.cmake passé en argument de 'cmake', voir compile.bat)
if(WIN32)
    list(APPEND CMAKE_PREFIX_PATH "C:/SFML-3.0.0")  # Adapter au chemin réel du SDK SFML
endif()

# 2. Trouver le package SFML 3
find_package(SFML 3 COMPONENTS Graphics Window System REQUIRED)

# 3. Lier SFML à votre cible (Remplacez "MonProjet" par le nom exact de votre exécutable)
target_link_libraries(JeuDeLaVie PRIVATE
                        SFML::Graphics
                        SFML::Window
                        SFML::System
                     )


# COMPILATION BINAIRE UNIVERSEL ##############################################################
# macOS : binaire universel (Intel + Apple Silicon)
# BINAIRE UNIVERSEL FINALEMENT DÉSACTIVÉ COMPTE TENU DE LA NÉCESSITÉ DE DISPOSER D'UNE VERSION
# INTEL DE LA LIB À INSTALLER EN PARALLÈLE VERS USR/LOCAL/
# LE RAPPORT UTILITÉ/COMPLEXITÉ EST JUGÉ PEU FAVORABLE
if(APPLE)
    set_target_properties(JeuDeLaVie PROPERTIES
        #OSX_ARCHITECTURES "x86_64;arm64"
        #OSX_ARCHITECTURES "x86_64"
        #OSX_ARCHITECTURES "arm64"
        MACOSX_BUNDLE OFF
    )
endif()



# INSTALLATION (SECTION FACULTATIVE) #########################################################
# Permet de définir où sera installé l'exécutable si l'on choisi de l'intégrer au système
# Cette installation se faisant alors par un 'cmake --install build/' ou un 'make install'
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
