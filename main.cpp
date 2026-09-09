#include <SFML/Graphics.hpp>
#include <SFML/Window/Event.hpp>
#include <SFML/Window/Keyboard.hpp>

#include <cstdlib>
#include <optional>

#include "JeuDeLaVie.h"


int main() {

    auto desktop = sf::VideoMode::getDesktopMode();
    int width  = desktop.size.x / CELL_SIZE;    // Largeur d'écran exprimée en nbre de cellules

    // Hauteur réduite pour transition haut/bas fluide (le pb ne semble pas se poser latéralement)
    int height = desktop.size.y / CELL_SIZE -8; // Hauteur d'écran exprimée en nbre de cellules

    std::string titre = "Le Jeu de la Vie  -  EN PAUSE";

    sf::RenderWindow window(sf::VideoMode({desktop.size.x, desktop.size.y}),
                            titre,
                            sf::Style::Titlebar | sf::Style::Close);

    sf::Vector2i mouse_cursor;
    Grid<bool> actu_state(static_cast<std::size_t>(width),
                          static_cast<std::size_t>(height));
    Grid<bool> next_state(static_cast<std::size_t>(width),
                          static_cast<std::size_t>(height));
    bool running = false;
    int cellX, cellY;
    Grid<sf::RectangleShape> cells(static_cast<std::size_t>(width),
                                   static_cast<std::size_t>(height));


    // Horloge dédiée à la cadence de simulation, indépendante du framerate d'affichage
    sf::Clock generation_clock;

    window.setFramerateLimit(60);

    init(actu_state, next_state, cells);

    while (window.isOpen()) {
        // --- Gestion des événements : fermeture et appuis ponctuels sur une touche ---
        while (const std::optional event = window.pollEvent()) {
            if (event->is<sf::Event::Closed>())
                window.close();

            if (const auto* keyPressed = event->getIf<sf::Event::KeyPressed>()) {

                mouse_cursor = sf::Mouse::getPosition(window);
                cellX = mouse_cursor.x / CELL_SIZE;
                cellY = mouse_cursor.y / CELL_SIZE;

                switch (keyPressed->code) {

                    case sf::Keyboard::Key::Escape :
                        // 'Touche Échap.' --> Bascule marche /pause
                        window.close();
                        break;

                    case sf::Keyboard::Key::Space :
                        // 'Barre d'espace' --> Bascule marche /pause
                        // (au lieu de ne pouvoir que "démarrer")
                        running = !running;
                        if (running == true) window.setTitle("Le Jeu de la Vie  -  RUNNING");
                        else                 window.setTitle("Le Jeu de la Vie  -  EN PAUSE");
                        generation_clock.restart();
                        break;

                    case sf::Keyboard::Key::E :
                        // 'E' au clavier --> Efface la grille sans forcément
                        // arrêter la simulation
                        clear_grid(actu_state, next_state, cells);
                        break;

                    case sf::Keyboard::Key::R :
                        // Réinitialise complètement : efface et met en pause
                        clear_grid(actu_state, next_state, cells);
                        running = false;
                        break;

                    case sf::Keyboard::Key::P :
                        // 'P' au clavier --> Insère un planeur à la position
                        // du pointeur de la souris dans la fenêtre de jeu
                        insert_glider(cellX, cellY, actu_state);
                        break;

                    case sf::Keyboard::Key::L :
                        // 'L' au clavier --> Insère un LWSS à la position
                        // du pointeur de la souris dans la fenêtre de jeu
                        insert_LWSS(cellX, cellY, actu_state);
                        break;

                    case sf::Keyboard::Key::C :
                        // 'C' au clavier --> Insère un canon à la position
                        // du pointeur de la souris dans la fenêtre de jeu
                        insert_cannon(cellX, cellY, actu_state);
                        break;

                    default:
                        break;
                }
            }
        }

        // Édition de la grille à la souris (lecture en continu, hors file d'événements) ---
        mouse_cursor = sf::Mouse::getPosition(window);
        cellX = mouse_cursor.x / CELL_SIZE;
        cellY = mouse_cursor.y / CELL_SIZE;

        // Empêche tout débordement d'indice (positif ou négatif)
        if (cellX >= static_cast<int>(actu_state.width()))  cellX = static_cast<int>(actu_state.width()) - 1;
        if (cellY >= static_cast<int>(actu_state.height())) cellY = static_cast<int>(actu_state.height()) - 1;
        if (cellX < 0) cellX = 0;
        if (cellY < 0) cellY = 0;

        if (mouse_cursor.x > 0 && mouse_cursor.y > 0 &&
            mouse_cursor.x < static_cast<int>(desktop.size.x) &&
            mouse_cursor.y < static_cast<int>(desktop.size.y)) {

            if (sf::Mouse::isButtonPressed(sf::Mouse::Button::Left)) {
                cells(cellX, cellY).setFillColor(sf::Color::Black);
                actu_state(cellX, cellY) = LIVE;
            }

            if (sf::Mouse::isButtonPressed(sf::Mouse::Button::Right)) {
                cells(cellX, cellY).setFillColor(ARGENT);
                actu_state(cellX, cellY) = DEAD;
            }
        }

        // Simulation cadencée : une génération toutes les GENERATION_INTERVAL_MS
        if (running &&
            generation_clock.getElapsedTime().asMilliseconds() >= GENERATION_INTERVAL_MS) {

            run(actu_state, next_state, cells);
            generation_clock.restart();
        }

        window.clear();
        draw_grid(&window, cells);
        window.display();
    }

    return EXIT_SUCCESS;
}


