# FICHE : Library Playlist Detail

# Cas 1 — Desktop / TV, état principal chargé

## Général

Entrée focus -> Bouton "Play Random"  
Mémoire du focus au retour -> Oui, sur le dernier élément interactif encore présent si possible  
Fallback si impossible -> Bouton "Play Random"  
BACK global de la page -> Retour à la page précédente

## Apparence du focus

- Bouton "Play Random" -> contour clair visible + fond légèrement renforcé
- Bouton retour -> anneau de focus net autour du bouton rond
- Bouton "Sort" -> anneau clair autour du bouton rond
- Item playlist -> carte entière surlignée, bord plus lumineux, élévation légère ou agrandissement subtil
- Bouton "More" d’un item -> focus appliqué sur le bouton rond lui-même, très visible mais sans masquer la carte
- Bouton "More playlist" -> même logique que les autres boutons ronds
- Le focus doit être très lisible sur fond visuel/hero, sans ambiguïté sur l’élément actif

## Bouton "Play Random"

### Comportement attendu par action

UP ↑ => Bouton retour  
DOWN ↓ => Premier élément playlist  
LEFT ← => Bloqué  
RIGHT → => Bouton "Sort"

### Validation / action

CLICK / OK / ENTER => Lance la lecture aléatoire

### Retour

BACK / ESC => Retour à la page précédente

---

## Bouton "Sort"

### Comportement attendu par action

UP ↑ => Bouton retour  
DOWN ↓ => Premier élément playlist  
LEFT ← => Bouton "Play Random"  
RIGHT → => Bloqué

### Validation / action

CLICK / OK / ENTER => Ouvre le menu de tri

### Retour

BACK / ESC => Retour à la page précédente

---

## Bouton retour

### Comportement attendu par action

UP ↑ => Bloqué  
DOWN ↓ => Bouton "Play Random"  
LEFT ← => Bloqué  
RIGHT → => Bouton "More playlist" si visible, sinon reste sur place

### Validation / action

CLICK / OK / ENTER => Retour à la page précédente

### Retour

BACK / ESC => Retour à la page précédente

---

## Bouton "More playlist" (si visible)

### Comportement attendu par action

UP ↑ => Bloqué  
DOWN ↓ => Bouton "Sort"  
LEFT ← => Bouton retour  
RIGHT → => Bloqué

### Validation / action

CLICK / OK / ENTER => Ouvre le menu playlist

### Retour

BACK / ESC => Retour à la page précédente

---

## Premier élément playlist

### Comportement attendu par action

UP ↑ => Bouton "Play Random"  
DOWN ↓ => Élément suivant dans la liste  
LEFT ← => Bloqué  
RIGHT → => Bouton "More" de cet élément si visible, sinon bloqué

### Validation / action

CLICK / OK / ENTER => Ouvre la fiche du média

### Retour

BACK / ESC => Retour à la page précédente

---

## Élément playlist intermédiaire

### Comportement attendu par action

UP ↑ => Élément précédent  
DOWN ↓ => Élément suivant  
LEFT ← => Bloqué  
RIGHT → => Bouton "More" de cet élément si visible, sinon bloqué

### Validation / action

CLICK / OK / ENTER => Ouvre la fiche du média

### Retour

BACK / ESC => Retour à la page précédente

---

## Dernier élément playlist

### Comportement attendu par action

UP ↑ => Élément précédent  
DOWN ↓ => Bloqué  
LEFT ← => Bloqué  
RIGHT → => Bouton "More" de cet élément si visible, sinon bloqué

### Validation / action

CLICK / OK / ENTER => Ouvre la fiche du média

### Retour

BACK / ESC => Retour à la page précédente

---

## Bouton "More" d’un item (si visible)

### Comportement attendu par action

UP ↑ => Bouton "More" de l’item précédent si visible, sinon item précédent  
DOWN ↓ => Bouton "More" de l’item suivant si visible, sinon item suivant  
LEFT ← => Carte/item correspondant  
RIGHT → => Bloqué

### Validation / action

CLICK / OK / ENTER => Ouvre le menu d’options de l’item

### Retour

BACK / ESC => Ferme le menu si ouvert, sinon retour à la page précédente

---

# Cas 3 — Chargement

## Général

Entrée focus -> Aucun focus utile sur le contenu  
Mémoire du focus au retour -> Non applicable  
Fallback si impossible -> Aucun  
BACK global de la page -> Retour à la page précédente si autorisé par le flux

## Apparence du focus

- Aucun focus visuel important ne doit être montré sur le spinner
- Si un focus technique existe, il doit rester invisible pour ne pas donner l’impression qu’une action est possible
- L’écran doit paraître passif tant que les données ne sont pas prêtes

## Zone de chargement

UP ↑ => Bloqué  
DOWN ↓ => Bloqué  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Aucune action  
BACK / ESC => Retour à la page précédente si autorisé

---

# Cas 4 — Erreur

## Général

Entrée focus -> Aucun interactif visible garanti  
Mémoire du focus au retour -> Non  
Fallback si impossible -> Aucun  
BACK global de la page -> Retour à la page précédente

## Apparence du focus

- Si aucun bouton n’est affiché, aucun focus visible ne doit suggérer une action
- Le message d’erreur doit rester purement informatif
- Si plus tard un bouton Retry est ajouté, il devra devenir la cible d’entrée naturelle

## Zone erreur

UP ↑ => Bloqué  
DOWN ↓ => Bloqué  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Aucune action  
BACK / ESC => Retour à la page précédente

---

# Cas 5 — Playlist vide

## Général

Entrée focus -> Bouton retour  
Mémoire du focus au retour -> Oui si retour depuis une autre page, sinon non pertinent  
Fallback si impossible -> Bouton retour  
BACK global de la page -> Retour à la page précédente

## Apparence du focus

- Bouton retour bien visible : fond gris moyen rond
- Boutons d’actions désactivés visuellement distincts
- Le focus ne doit pas aller par défaut sur un bouton désactivé
- Le message vide reste non interactif

## Bouton retour

UP ↑ => Bloqué  
DOWN ↓ => Bloqué, ou "More playlist" si visible et interactif  
LEFT ← => Bloqué  
RIGHT → => Bouton "More playlist" si visible, sinon bloqué

CLICK / OK / ENTER => Retour à la page précédente  
BACK / ESC => Retour à la page précédente

---

## Bouton "More playlist" (si visible)

UP ↑ => Bloqué  
DOWN ↓ => Bloqué  
LEFT ← => Bouton retour  
RIGHT → => Bloqué

CLICK / OK / ENTER => Ouvre le menu playlist  
BACK / ESC => Retour à la page précédente

---

## Bouton "Play Random" désactivé

UP ↑ => Bouton retour ou bloqué selon politique de focus  
DOWN ↓ => Bloqué  
LEFT ← => Bloqué  
RIGHT → => Bouton "Sort" si focusable, sinon bloqué

CLICK / OK / ENTER => Aucune action  
BACK / ESC => Retour à la page précédente

Note UX -> Mieux vaut éviter que le focus d’entrée tombe sur un bouton désactivé.

---

# Cas 6 — Menu de tri ouvert

## Général

Entrée focus -> Option de tri actuellement sélectionnée  
Mémoire du focus au retour -> Oui, retour au bouton "Sort" après fermeture  
Fallback si impossible -> Première option de tri  
BACK global de la page -> Ferme le menu

## Apparence du focus

- L’option focusée doit être clairement surlignée ligne entière
- L’option sélectionnée peut avoir une coche persistante
- Le focus et l’état sélectionné doivent rester distinguables
- "Cancel" doit avoir un style de bouton secondaire mais focus très visible

## Option de tri

UP ↑ => Option précédente, ou bloqué si première  
DOWN ↓ => Option suivante, ou bouton "Cancel" si dernière option  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Applique le tri et ferme le menu  
BACK / ESC => Ferme le menu sans changer la page

---

## Bouton "Cancel"

UP ↑ => Dernière option de tri  
DOWN ↓ => Bloqué  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Ferme le menu  
BACK / ESC => Ferme le menu

---

# Cas 7 — Menu playlist ouvert

## Général

Entrée focus -> Première action du menu  
Mémoire du focus au retour -> Oui, retour sur "More playlist"  
Fallback si impossible -> Première action disponible  
BACK global de la page -> Ferme le menu

## Apparence du focus

- Chaque ligne du menu doit recevoir un focus plein largeur
- "Delete" garde son ton destructif même focusé
- "Cancel" reste secondaire mais clairement focusable

## Action "Rename"

UP ↑ => Bloqué  
DOWN ↓ => Action "Delete"  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Ouvre le dialog de renommage  
BACK / ESC => Ferme le menu

---

## Action "Delete"

UP ↑ => Action "Rename"  
DOWN ↓ => Bouton "Cancel"  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Ouvre le dialog de suppression  
BACK / ESC => Ferme le menu

---

## Bouton "Cancel"

UP ↑ => Action "Delete"  
DOWN ↓ => Bloqué  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Ferme le menu  
BACK / ESC => Ferme le menu

---

# Cas 8 — Menu d’options d’un item

## Général

Entrée focus -> Première action du menu  
Mémoire du focus au retour -> Oui, retour sur le bouton "More" de l’item concerné  
Fallback si impossible -> Première action disponible  
BACK global de la page -> Ferme le menu

## Apparence du focus

- Focus appliqué sur chaque ligne d’action
- "Delete" reste destructif
- "Add to list" reste action principale neutre
- Le retour au bouton "More" doit restaurer un focus clair

## Action "Delete"

UP ↑ => Bloqué  
DOWN ↓ => Action "Add to list"  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Supprime l’item si confirmé dans l’étape suivante  
BACK / ESC => Ferme le menu

---

## Action "Add to list"

UP ↑ => Action "Delete"  
DOWN ↓ => Bouton "Cancel"  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Ouvre la sélection de liste  
BACK / ESC => Ferme le menu

---

## Bouton "Cancel"

UP ↑ => Action "Add to list"  
DOWN ↓ => Bloqué  
LEFT ← => Bloqué  
RIGHT → => Bloqué

CLICK / OK / ENTER => Ferme le menu  
BACK / ESC => Ferme le menu