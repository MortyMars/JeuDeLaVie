#pragma once

#include <SFML/Graphics.hpp>
#include <SFML/Window/Event.hpp>
#include <SFML/Window/Keyboard.hpp>

#include <cstdlib>
#include <cstddef>
#include <deque>
#include <algorithm>

// ÉTAT DES CELLULES
#define DEAD 0          // cellule morte   = 0
#define LIVE 1          // cellule vivante = 1

// VITESSE DE SIMULATION (1 génération ttes les X ms)
#define GENERATION_INTERVAL_MS 100

// COMBINAISONS DE COULEURS PRÉDÉFINIES
#define ARGENT  sf::Color(206,206,206)
#define CARMIN  sf::Color(150,0,24)
#define GAZON   sf::Color(58,137,35)
#define ARDOISE sf::Color(104,111,140)

// TAILLE D'UNE CELLULE (celle-ci PEUT rester une macro : elle ne sert jamais
// de dimension de tableau, juste de coefficient de calcul -> aucune contrainte
// de "constant expression" liée au système de types)
#define CELL_SIZE 8 // 12 à l'origine


/* ----------------------------------------------------------------------------------------------------------
POURQUOI 'WIDTH' ET 'HEIGHT' NE SONT PLUS DES #define ICI

Rappel du problème rencontré : dès qu'une dimension de grille sert de taille de tableau dans le TYPE d'un
paramètre de fonction (ex: 'bool actu_state[][HEIGHT]'), le compilateurexige que cette dimension soit une
expression constante évaluable à la compilation. Or sf::VideoMode::getDesktopMode() est un appel résolu à
l'exécution : il ne peut donc plus servir de dimension de tableau C-style.

La solution retenue : abandonner le tableau C-style multidimensionnel au profit d'une petite classe 'Grid<T>'
qui stocke ses données dans un std::vector<T> "aplati" (1 dimension), et qui garde width/height comme de
simples variables membres, connues seulement à l'exécution (donc calculables depuis la résolution d'écran,
sans aucune contrainte de compilation).

Avantage : WIDTH et HEIGHT peuvent être calculés dynamiquement, tous les deux, sans piège.
Coût : l'accès à une cellule se fait via grid(x, y) [operator()] au lieu de grid[x][y].

NOTE : le conteneur interne est un 'std::deque' et non un 'std::vector'. Raison : 'std::vector<bool>' est
"spécialisé" par le standard C++ pour compresser les booléens en bits individuels (économie mémoire).
Du coup, 'm_data[i]' ne renvoie pas un vrai 'bool&', mais un objet 'std::vector<bool>::reference' qui ne peut
pas être retourné en tant que T&. 'std::deque' n'a pas cette spécialisation piégeuse : 'deque<bool>' stocke
de vrais bool avec de vraies références, ainsi operator() peut fonctionner avec tout T.
---------------------------------------------------------------------------------------------------------- */


// ==========================================================================================================
// Déclaration de la Classe Grid
// T est un type générique (la lettre T est conventionnelle), un type "à trou", rempli au moment de
// l'utilisation. Ainsi, on peut écrire aussi bien 'Grid<bool>' (pour les états DEAD/LIVE) que
// 'Grid<sf::RectangleShape>' (pour les rectangles). On utilise la même classe, rendue générique par l'emploi
// d'un type générique. Le compilateur génère une version spécialisée pour chaque T utilisé.
template <typename T>

class Grid {
    public:

        // CONSTRUCTEUR #1 : créé une grille vide
        // Utile lorsqu'on ne connait pas sa dimension à l'avance
        Grid() = default;

        /* Le vrai CONSTRUCTEUR, fait plusieurs choses dans la liste d'initialisation : stocke width et height,
        construit m_data directement avec width * height éléments, tous initialisés à init_value.
        'T init_value = T{}' = c'est la valeur par défaut du type générique (la valeur "zéro" du type T),
        équivalent à false pour un 'bool', ou à rectangle vide pour un 'sf::RectangleShape)'.
        'Grid<bool>(width, height)' construit donc une grille déjà pleine de false, sans avoir à le préciser. */
        Grid(std::size_t width, std::size_t height, T init_value = T{})
            : m_width(width), m_height(height), m_data(width * height, init_value) {}


        // MÉTHODES d'accès à la cellule (x, y)
        // On utilise une référence à T 'T&' pour que l'on modifie la grille réelle et non une
        // copie, ce qui aurait été le cas si on avait utilisé 'T' tout court
        //
        // OPÉRATEUR ORDINAIRE (PM : un opérateur est construit comme une méthode sans nom)
        T& operator()(int x, int y) {
                    return m_data[static_cast<std::size_t>(x) * m_height + static_cast<std::size_t>(y)];
        }
        // OPÉRATEUR SURCHARGÉ : Le const final dit "cette méthode ne modifie pas l'objet Grid".
        // Elle est utilisée automatiquement quand la grille elle-même est const
        // C'est le cas de 'count_neighbour(...)' , qui ne doit pas modifier la grille qu'on lui passe
        const T& operator()(int x, int y) const {
                    return m_data[static_cast<std::size_t>(x) * m_height + static_cast<std::size_t>(y)];
        }


        // MÉTHODES accesseurs en lecture seule, créées pour que le code appelant, 'run', 'draw_grid', ...
        // puisse connaître les dimensions sans accéder à 'm_width' et 'm_height' qui sont private.
        std::size_t width()  const { return m_width; }
        std::size_t height() const { return m_height; }


        // Méthode remettant toutes les cellules à une valeur donnée (par défaut la valeur "zéro" du type),
        // en une seule ligne, via l'algorithme standard std::fill qui parcourt tout m_data.
        void clear(T value = T{}) { std::fill(m_data.begin(), m_data.end(), value); }

    private:
        std::size_t m_width  = 0;
        std::size_t m_height = 0;

        // Déclaration de 'm_data' de type 'std::deque<T>'
        // Pourquoi ce choix plutôt que 'std::vector<T>' ou un tableau brut ? Car 'std::vector<bool>' est
        // piégeux (spécialisation en bits, casse operator()). 'std::deque' évite ce piège tout en gardant
        // une API proche de 'std::vector'. C'est un compromis pragmatique plus qu'un choix de performance.
        std::deque<T> m_data;

}; // !class Grid


// ==========================================================================================================
// Fonction inline wrap_coord
/*
Le monde du jeu est torique (déjà géré ainsi dans count_neighbour, via des modulos). Les cellules qui sortent
d'un bord réapparaissent de l'autre côté, à l'affichage comme à la simulation.

Problème : les méthodes 'insert_glider()', 'insert_LWSS()', et 'insert_cannon()' calculent des coordonnées
(X + décalage) qui peuvent devenir négatives ou dépasser width/height, notamment près des bords.
Or 'Grid::operator()' fait un 'static_cast<std::size_t>(x)' SANS vérification. Un x négatif devient, une fois
casté non signé, une valeur énorme -> accès mémoire hors bornes -> crash.

'wrap_coord()' ramène n'importe quelle coordonnée (aussi négative ou grande soit-elle) dans l'intervalle
[0, size[, en appliquant le même principe de modulo "torique" que count_neighbour, mais généralisé à n'importe
quel décalage (pas seulement ±1). Elle rend le comportement d'insertion cohérent avec le comportement de
simulation : un planeur inséré à cheval sur un bord se poursuit naturellement de l'autre côté, sans sortir des
bornes de la grille.   */
//
inline int wrap_coord(int coord, int size) {
    return ((coord % size) + size) % size;
}


// ==========================================================================================================
// Initialise les cellules pour chacune des grilles :
//      - actu_state : grille de bool pour l'état actuel des cellules
//      - next_state : grille de bool pour l'état des cellules au tour suivant
//      - cells      : grille des rectangles SFML (coordonnées à l'écran des cellules)
void init(Grid<bool>& actu_state,
          Grid<bool>& next_state,
          Grid<sf::RectangleShape>& cells);


// ==========================================================================================================
// Compte le nbre de voisines (vivantes) d'une cellule donnée, pour la grille d'état actuel
int count_neighbour(const Grid<bool>& actu_state,
                    int x,
                    int y);


// ==========================================================================================================
// Efface la grille et RAZ les états actuel et suivant
void clear_grid(Grid<bool>& actu_state,
                Grid<bool>& next_state,
                Grid<sf::RectangleShape>& cells);


// ==========================================================================================================
// Lance le jeu en définissant les règles
void run(Grid<bool>& actu_state,
         Grid<bool>& next_state,
         Grid<sf::RectangleShape>& cells);


// ==========================================================================================================
// Dessine la grille physique des cellules dans un état donné
void draw_grid(sf::RenderWindow *window,
               Grid<sf::RectangleShape>& cells);


// ==========================================================================================================
// Insertion d'un planeur.
void insert_glider(int x, int y, Grid<bool>& actu_state);


// ==========================================================================================================
// Insertion d'un LWSS.
void insert_LWSS(int x, int y, Grid<bool>& actu_state);


// ==========================================================================================================
// Insertion d'un canon à planeur.
void insert_cannon(int x, int y, Grid<bool>& actu_state);


// ==========================================================================================================
// Détermination d'une direction de déplacement aléatoire
// (applicable à l'insertion d'un Planeur ou d'un LWSS)
int setDirAleatoire();
