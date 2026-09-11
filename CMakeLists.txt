# ============================================================================
#  JeuDeLaVie  -  CMakeLists.txt (Version Universelle macOS Propre)
# ============================================================================

cmake_minimum_required(VERSION 3.16)

if(APPLE)
    # Force la compatibilité rétroactive avec les anciens Mac (macOS 13 Ventura minimum)
    # Requis pour éviter le message "built for macOS 26.0"
    set(CMAKE_OSX_DEPLOYMENT_TARGET "13.0" CACHE STRING "Version minimale de macOS supportée" FORCE)

    # Force la compilation pour les deux architectures en simultané
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "Architectures cibles" FORCE)
    
    set(SFML_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/sfml-macos/include")
    set(SFML_SILICON_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/sfml-macos/silicon/lib")
    set(SFML_INTEL_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/sfml-macos/intel/lib")
endif()

project(JeuDeLaVie LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Mode de compilation" FORCE)
endif()

add_executable(JeuDeLaVie
    JeuDeLaVie.h      
    JeuDeLaVie.cpp    
    main.cpp          
)

if(APPLE)
    target_include_directories(JeuDeLaVie PRIVATE "${SFML_INCLUDE_DIR}")
    
    # Flags magiques d'Apple : on aiguille le compilateur vers le bon dossier selon l'architecture qu'il traite
    target_link_options(JeuDeLaVie PRIVATE
        "-Xarch_arm64" "-L${SFML_SILICON_LIB_DIR}"
        "-Xarch_x86_64" "-L${SFML_INTEL_LIB_DIR}"
    )

    target_link_libraries(JeuDeLaVie PRIVATE
        sfml-graphics
        sfml-window
        sfml-system
    )
else()
    find_package(SFML 3 COMPONENTS Graphics Window System REQUIRED)
    target_link_libraries(JeuDeLaVie PRIVATE 
        SFML::Graphics 
        SFML::Window 
        SFML::System
    )
endif()

