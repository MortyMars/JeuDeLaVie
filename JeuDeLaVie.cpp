#include <SFML/Graphics.hpp>
#include <SFML/Window/Event.hpp>
#include <SFML/Window/Keyboard.hpp>

#include <cstdlib>
#include <random>
#include <vector>

#include "JeuDeLaVie.h"


// ======================================================================================
// Initialise les cellules pour chacune des grilles :
//      - actu_stat : tableau de bool pour l'état actuel des cellules
//      - actu_stat : tableau de bool pour l'état des cellules au tour suivant
//      - cells     : tableau des coordonnées des cellules
void init(Grid<bool>& actu_state,
          Grid<bool>& next_state,
          Grid<sf::RectangleShape>& cells) {

    int width  = static_cast<int>(actu_state.width());
    int height = static_cast<int>(actu_state.height());

    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            actu_state(x, y) = DEAD;    // RAZ de l'état actuel sur DEAD
            next_state(x, y) = DEAD;    // RAZ de l'état suivant sur DEAD

            cells(x, y) = sf::RectangleShape(sf::Vector2f(CELL_SIZE, CELL_SIZE));

            //cells(x, y).setFillColor(sf::Color::White);
            cells(x, y).setFillColor(ARGENT);               // couleur de remplissage

            //cells(x, y).setOutlineColor(sf::Color::Red);
            cells(x, y).setOutlineColor(ARDOISE);           // couleur du contour

            //cells(x, y).setOutlineThickness(2.f);
            cells(x, y).setOutlineThickness(1.f);           // épaisseur du contour

            cells(x, y).setPosition({static_cast<float>(x * CELL_SIZE + 2),
                                     static_cast<float>(y * CELL_SIZE + 2)});
        }
    }

} // !init()


// ======================================================================================
// Comptage des voisines vivantes d'une cellule, ce qui déterminera son état suivant
int count_neighbour(const Grid<bool>& actu_state,
                    int x,
                    int y) {

    int width  = static_cast<int>(actu_state.width());
    int height = static_cast<int>(actu_state.height());

    int number_neighbour = 0;
    int left;
    int right = (x + 1) % width;
    int up;
    int down = (y + 1) % height;


    // Vérifier la présence de valeurs négatives (avec un modulo), pour créer une grille infinie
    if (x - 1 < 0)  left = width - (abs(x - 1) % width);
    else            left = (x - 1) % width;

    if (y - 1 < 0)  up = height - (abs(y - 1) % height);
    else            up = (y - 1) % height;


    // VÉRIFICATION DES 8 CELLULES VOISINES :

    // en diagonale, en haut à gauche
    if (actu_state(left, up)    == LIVE)    number_neighbour++;

    // au dessus
    if (actu_state(x, up)       == LIVE)    number_neighbour++;

    // en diagonale, en haut à droite
    if (actu_state(right, up)   == LIVE)    number_neighbour++;

    // à gauche
    if (actu_state(left, y)     == LIVE)    number_neighbour++;

    // à droite
    if (actu_state(right, y)    == LIVE)    number_neighbour++;

    // en diagonale, en bas à gauche
    if (actu_state(left, down)  == LIVE)    number_neighbour++;

    // au dessous
    if (actu_state(x, down)     == LIVE)    number_neighbour++;

    // en diagonale, en bas à droite
    if (actu_state(right, down) == LIVE)    number_neighbour++;



    return number_neighbour;    // nbre total de voisines vivantes

} // !count_neighbour()


// ======================================================================================
// Nettoyage de la grille
void clear_grid(Grid<bool>& actu_state,
                Grid<bool>& next_state,
                Grid<sf::RectangleShape>& cells) {

    int width  = static_cast<int>(actu_state.width());
    int height = static_cast<int>(actu_state.height());

    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            actu_state(x, y) = DEAD;
            next_state(x, y) = DEAD;
            cells(x, y).setFillColor(ARGENT);
        }
    }
}


// ======================================================================================
// MOTEUR DU JEU - RAPPEL DE LA RÈGLE SIMPLE
// Une cellule ayant :
//  - 3 voisines vivantes, sera VIVANTE au prochain état                     -> CAS 1
//  - 2 voisines vivantes, sera INCHANGÉE au prochain état                   -> CAS 2
//  - moins de 2 ou plus de 3 voisines vivantes, sera MORTE au prochain état -> CAS 3
void run(Grid<bool>& actu_state,
         Grid<bool>& next_state,
         Grid<sf::RectangleShape>& cells) {

    int width  = static_cast<int>(actu_state.width());
    int height = static_cast<int>(actu_state.height());

    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            int number_neighboor = count_neighbour(actu_state, x, y);

            // Cas simplifiés car le test ne porte pas sur l'état actuel de la cellule
            // CAS 1
            if (number_neighboor == 3)
                next_state(x, y) = LIVE;
            // CAS 2
            if (number_neighboor == 2)
                next_state(x, y) = actu_state(x, y);
            // CAS 3
            if (number_neighboor < 2 || number_neighboor > 3)
                next_state(x, y) = DEAD;
        }
    }

    // Colorisation de chaque cellule selon modification de son état
    // Puis mise à jour du nouvel état de la cellule
    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {

            // Colorisation de la cellule
            if (actu_state(x, y) == LIVE && next_state(x, y) == LIVE)       // vivante inchangé
                cells(x, y).setFillColor(sf::Color::Black);                 // -> noir

            else if (actu_state(x, y) == DEAD && next_state(x, y) == LIVE)  // naissance d'une cellule
                cells(x, y).setFillColor(GAZON);                            // ->vert gazon

            else if (actu_state(x, y) == LIVE && next_state(x, y) == DEAD)  // mort d'une cellule
                cells(x, y).setFillColor(CARMIN);                           // -> rouge carmin

            else                                                            // morte inchangé
                cells(x, y).setFillColor(ARGENT);                           // -> argent


            // MàJ de l'état de la cellule
            actu_state(x, y) = next_state(x, y);

        }
    }

} // !run()


// ======================================================================================
// Dessin de la grille
void draw_grid(sf::RenderWindow *window,
               Grid<sf::RectangleShape>& cells) {

    int width  = static_cast<int>(cells.width());
    int height = static_cast<int>(cells.height());

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
         window->draw(cells(x, y));
      }
    }
}


// ======================================================================================
// Insertion en (X,Y) d'un planeur à déplacement diagonal aléatoire
// Le planeur est le + petit des vaisseaux diagonaux (5 cellules)
void insert_glider(int X, int Y, Grid<bool>& actu_state) {

    int width  = static_cast<int>(actu_state.width());
    int height = static_cast<int>(actu_state.height());

    // Le nombre aléatoire 'direction' détermine quel zone est à effacer
    // et quel cas de construction appliquer
    int direction = setDirAleatoire();


    // NETTOYAGE DE L'EMPLACEMENT DU PLANEUR --------------------------------------------
    // La zone de nettoyage s'étend au périmètre de chacune des 4 générations
    // possibles d'un planeur, augmenté d'une bordure d'une cellule de largeur
    //
    // Déclaration de 'Cellule'
    struct Cellule { int cx; int cy; };
    //      Définition de la zone rectangulaire à effacer
    std::vector<Cellule> Zone = {};
    //
    // Bornes de la zone à effacer, fonction de la direction déterminée aléatoirement
    int xmin=0, xmax=0, ymin=0, ymax=0; // Initialiées car râlage du compilateur...
    switch (direction) {
        case 0 : xmin = -1; xmax = +3; ymin = -1; ymax = +3; break; // empreinte planeur Sud-Est
        case 1 : xmin = -3; xmax = +1; ymin = -1; ymax = +3; break; // empreinte planeur Sud-Ouest
        case 2 : xmin = -1; xmax = +3; ymin = -3; ymax = +1; break; // empreinte planeur Nord-Est
        case 3 : xmin = -3; xmax = +1; ymin = -3; ymax = +1; break; // empreinte planeur Nord-Ouest
    }
    //
    // Ajout des cellules au conteneur 'zone'
    for (int cx = xmin; cx <= xmax; cx++) {
        for (int cy = ymin; cy <= ymax; cy++) {
            Zone.push_back({cx,cy});
        }
    }
    //
    // Nettoyage proprement dit (wrap_coord empêche tout débordement d'index près des bords)
    for (const auto& cell : Zone){
        actu_state(wrap_coord(X + cell.cx, width),
                   wrap_coord(Y + cell.cy, height)) = DEAD;
    }


    // DÉTERMINATION DES CELLULES COMPOSANT LE PLANEUR ----------------------------------
    //
    //Déclaration de 'Point'
    struct Point { int dx; int dy; };
    //
    // Il y a 4 constructions de planeur correspondant aux 4 directions de déplacement
    // elles dérivent d'une forme de base
    std::vector<Point> baseGlider = {{1,0}, {2,1}, {0,2}, {1,2}, {2,2}};
    //
    // Bloc de modification de la construction de base ('baseGlider')
    for (const auto& pt : baseGlider) {
        int dxMod = pt.dx;
        int dyMod = pt.dy;
        // On utilise le même nombre aléatoire 'direction' déterminé plus haut
        // pour être sûr que le masque d'effacement et le dessin concordent
        switch (direction) {
        case 0: break;                                  // Sud-Est
        case 1: dxMod = -pt.dx; break;                  // Sud-Ouest
        case 2: dyMod = -pt.dy; break;                  // Nord-Est
        case 3: dxMod = -pt.dx; dyMod = -pt.dy; break;  // Nord-Ouest
        }
        // Activation du point (wrap_coord empêche tout débordement d'index près des bords :
        // le planeur se poursuit naturellement de l'autre côté du monde torique)
        actu_state(wrap_coord(X + dxMod, width),
                   wrap_coord(Y + dyMod, height)) = LIVE;
    }

} // !insert_glider()


// ======================================================================================
// Insertion en (X, Y) d'un LWSS à déplacement orthogonal aléatoire
// Le LWSS (LightWeight SpaceShip) est le + petit des vaisseaux orthogonaux (9 cellules)
void insert_LWSS(int X, int Y, Grid<bool>& actu_state) {

    int width  = static_cast<int>(actu_state.width());
    int height = static_cast<int>(actu_state.height());

    // Le nombre aléatoire 'direction' détermine quel zone est à effacer
    // et quel cas de construction appliquer
    int direction = setDirAleatoire();


    // NETTOYAGE DE L'EMPLACEMENT DU LWSS -----------------------------------------------
    // La zone de nettoyage s'étend au périmètre de chacune des 4 générations
    // possibles d'un planeur, augmenté d'une bordure d'une cellule de largeur
    //
    // Déclaration de 'Cellule'
    struct Cellule { int cx; int cy; };
    //      Définition de la zone rectangulaire à effacer
    std::vector<Cellule> Zone = {};
    //
    // Bornes de la zone à effacer, fonction de la direction déterminée aléatoirement
    int xmin=0, xmax=0, ymin=0, ymax=0; // Initialisées car râlage du compilateur...
    switch (direction) {
    case 0 : xmin = -1; xmax = +5; ymin = -1; ymax = +4; break; // empreinte LWSS Est
    case 1 : xmin = -5; xmax = +1; ymin = -1; ymax = +4; break; // empreinte LWSS Ouest
    case 2 : xmin = -1; xmax = +4; ymin = -1; ymax = +5; break; // empreinte LWSS Sud
    case 3 : xmin = -1; xmax = +4; ymin = -5; ymax = +1; break; // empreinte LWSS Nord
    }
    //
    // Ajout des cellules au conteneur 'zone'
    for (int cx = xmin; cx <= xmax; cx++) {
        for (int cy = ymin; cy <= ymax; cy++) {
            Zone.push_back({cx,cy});
        }
    }
    //
    // Nettoyage proprement dit (wrap_coord empêche tout débordement d'index près des bords)
    for (const auto& cell : Zone){
        actu_state(wrap_coord(X + cell.cx, width),
                   wrap_coord(Y + cell.cy, height)) = DEAD;
    }


    // DÉTERMINATION DES CELLULES COMPOSANT LE LWSS -------------------------------------
    //
    // Déclaration de 'Point'
    struct Point { int dx; int dy; };
    //
    // Il y a 4 constructions de LWSS correspondant aux 4 directions de déplacement
    // Le nombre aléatoire 'direction' détermine quel cas de construction appliquer
    std::vector<Point>
        baseLWSS = {{1,0}, {4,0}, {0,1}, {0,2}, {4,2}, {0,3}, {1,3}, {2,3}, {3,3}};
    //
    // Bloc de modification de la construction de base ('baseLWSS')
    for (const auto& pt : baseLWSS) {
        int dxMod = pt.dx;
        int dyMod = pt.dy;
        // On utilise le même nombre aléatoire 'direction' déterminé plus haut
        // pour être sûr que le masque d'effacement et le dessin concordent
        switch (direction) {
        case 0: break;                                  // Est (Droite)
        case 1: dxMod = -pt.dx; break;                  // Ouest (Gauche)
        case 2: dxMod = pt.dy; dyMod = pt.dx; break;    // Sud (Bas)
        case 3: dxMod = pt.dy; dyMod = -pt.dx; break;   // Nord (Haut)
        }
        // Activation du point (wrap_coord empêche tout débordement d'index près des bords)
        actu_state(wrap_coord(X + dxMod, width),
                   wrap_coord(Y + dyMod, height)) = LIVE;
    }

} // !insert_LWSS()


// ======================================================================================
// Insertion d'un canon à planeur en (X,Y)
void insert_cannon(int X, int Y, Grid<bool>& actu_state) {

    int width  = static_cast<int>(actu_state.width());
    int height = static_cast<int>(actu_state.height());

    // NETTOYAGE DE L'EMPLACEMENT DU CANON, avec un débord de +3 cellules
    // pour assurer le meilleur fonctionnement possible du canon
    //      Déclaration de 'Cellule'
    struct Cellule { int cx; int cy; };
    //      Définition de la zone rectangulaire à effacer
    std::vector<Cellule> zone = {};
    for (int cx = -3; cx < +38; cx++) {
        for (int cy = -7; cy < +7; cy++) {
            zone.push_back({cx,cy});
        }
    }
    // Nettoyage proprement dit (wrap_coord empêche tout débordement d'index près des bords)
    for (const auto& cell : zone){
        actu_state(wrap_coord(X + cell.cx, width),
                   wrap_coord(Y + cell.cy, height)) = DEAD;
    }


    // DÉFINITION DES CELLULES COMPOSANT LE CANON
    //      Déclaration de 'Point'
    struct Point { int dx; int dy; };
    //      Définition du vecteur de 'Point'
    std::vector<Point> cannon = {

        // DESSIN DU CANON (de la G vers la D)
        // 1er carré
        {0 , 0}, {1 , 0}, {0 , 1}, {1 , 1},

        // 1er bloc C-)
        {10, 0}, {10, 1}, {10, 2},
        {11,-1}, {11, 3},
        {12,-2}, {13,-2},
        {12, 4}, {13, 4},
        {14, 1},
        {15,-1}, {15, 3}, {16, 0}, {16, 1}, {16, 2}, {17, 1},

        // 2ème bloc cI
        {20,-2}, {20,-1}, {20, 0}, {21,-2}, {21,-1}, {21, 0},
        {22,-3}, {22, 1},
        {24,-4}, {24,-3}, {24, 1}, {24, 2},

        // 2ème carré
        {34,-2}, {34,-1}, {35,-2}, {35,-1}

    };
    //      Boucle d'activation des points
    for (const auto& pt : cannon) {

        // Activation du point (wrap_coord empêche tout débordement d'index près des bords)
        actu_state(wrap_coord(X + pt.dx, width),
                   wrap_coord(Y + pt.dy, height)) = LIVE;
    }


} // !insert_cannon()


// ======================================================================================
// Détermination d'une direction de déplacement aléatoire
// (Moteur de rendu aléatoire moderne C++)
// Le nbre aléatoire généré (entre 0 et 3) permet de rendre aléatoire la naissance d'un
// planeur ou d'un LWSS, parmi les 4 formes (et les 4 sens de déplacement) possibles de
// ces vaisseaux
int setDirAleatoire() {
        static std::random_device rd;
        static std::mt19937 gen(rd());
        std::uniform_int_distribution<> distr(0, 3);
        return distr(gen);
}
