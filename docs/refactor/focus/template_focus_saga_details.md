# FICHE : Saga Detail

## 1) Contexte
**Page :** Saga Detail  
**Couverture :** Hero, actions principales, liste / grille des films de la saga, overlays d’options

---

# Cas 1 — Desktop / TV, état principal chargé

## Général

**Entrée du focus =>** bouton **Play saga / Watch now**  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si encore présent  
**Fallback =>** bouton **Play saga / Watch now**  
**Retour global =>** retour à la page précédente  
**Sortie latérale gauche =>** shell latéral si présent

## Apparence du focus

### Bouton principal "Play saga / Watch now"
- **Focus =>** contour blanc 
- c’est l’action principale de la page, le focus doit être le plus évident ici

### Boutons ronds du hero
- **Back / More / Favorite / Shuffle éventuel =>** halo ou fond gris renforcé
- le focus doit rester très visible sur le hero

### Film de la saga
- **Focus =>** card entière mise en avant
- idéalement : contour accent + légère élévation / agrandissement subtil

### CTA secondaire éventuel
- **Focus =>** style visuel proche d’un bouton principal secondaire, clairement identifiable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Play saga / Watch now**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **More** sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "More" (si visible)

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Play saga / Watch now**  
**LEFT ← =>** bouton **Back** ou bouton précédent du hero  
**RIGHT → =>** bouton suivant du hero si présent, sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre le menu d’options

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Favorite" (si visible)

### Comportement attendu par action

**UP ↑ =>**  bouton **Back** 
**DOWN ↓ =>** premier film de la saga, ou élément de contenu le plus proche dessous  
**LEFT ← =>** bouton précédent du hero  
**RIGHT → =>** bouton suivant du hero si présent, sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** ajoute / retire la saga des favoris

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Play saga / Watch now"

### Comportement attendu par action

**UP ↑ =>** bouton **Back** 
**DOWN ↓ =>** premier film de la saga  
**LEFT ← =>** shell latéral si présent, sinon bloqué  
**RIGHT → =>** bouton hero suivant si présent, sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** lance la lecture du premier film pertinent / l’action principale de la saga

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Film de la saga

### Comportement attendu par action

**UP ↑ =>** film de la rangée au-dessus le plus proche, sinon bouton **Play saga / Watch now**  
**DOWN ↓ =>** film de la rangée en dessous le plus proche si il existe, sinon bloqué  
**LEFT ← =>** film précédent si il existe, sinon shell latéral si présent  
**RIGHT → =>** film suivant si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le film sélectionné

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 3 — Chargement

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** aucun  
**Retour global =>** retour à la page précédente

## Apparence du focus

- aucun élément ne doit paraître focusable
- le spinner / état de chargement doit rester purement informatif
- aucun contour ou halo de focus ne doit apparaître

## Zone de chargement

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 4 — Erreur simple

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non  
**Fallback =>** aucun  
**Retour global =>** retour à la page précédente

## Apparence du focus

- le message d’erreur reste purement informatif
- aucun bouton explicite visible dans cet état
- aucun focus ne doit suggérer une action possible

## Zone erreur

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** aucune action

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 5 — Saga vide / sans films affichables

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

- le bouton **Back** doit être le seul vrai point d’entrée focusable
- le message vide doit rester purement informatif
- aucun élément du corps de page ne doit sembler interactif

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** shell latéral si présent, sinon bloqué  
**RIGHT → =>** bouton hero suivant si présent, sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 6 — Menu "More" ouvert

## Général

**Entrée du focus =>** première action du menu  
**Mémoire du focus au retour =>** oui, retour sur le bouton **More** après fermeture  
**Fallback =>** première action disponible  
**Retour global =>** ferme le menu

## Apparence du focus

- chaque ligne du menu doit recevoir un focus pleine largeur
- l’action focusée doit être immédiatement identifiable
- l’action **Cancel** doit rester secondaire mais clairement focusable

## Action du menu

### Comportement attendu par action

**UP ↑ =>** action précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** action suivante si elle existe, sinon bouton **Cancel**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** exécute l’action sélectionnée

### Retour

**BACK / ESC =>** ferme le menu

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière action du menu  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ferme le menu

### Retour

**BACK / ESC =>** ferme le menu

---

# Cas 7 — Dialog / sheet "Ajouter à une liste"

## Général

**Entrée du focus =>** première playlist disponible  
**Mémoire du focus au retour =>** oui, retour sur l’action qui a ouvert le dialog  
**Fallback =>** première playlist disponible  
**Retour global =>** ferme le dialog

## Apparence du focus

- la playlist focusée doit être surlignée ligne entière ou card entière selon la présentation
- le fond derrière doit paraître inactif
- le bouton **Cancel** doit rester très lisible

## Playlist disponible

### Comportement attendu par action

**UP ↑ =>** playlist précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** playlist suivante si elle existe, sinon bouton **Cancel**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ajoute la saga ou ses films à la playlist sélectionnée, selon l’action proposée

### Retour

**BACK / ESC =>** ferme le dialog

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière playlist disponible  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ferme le dialog

### Retour

**BACK / ESC =>** ferme le dialog