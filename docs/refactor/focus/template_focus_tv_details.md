# FICHE : TV Detail

## 1) Contexte
**Page :** TV Detail  
**Couverture :** Hero, actions principales, bouton tracking, casting, onglets de saisons, liste d’épisodes, overlays d’options

---

# Cas 1 — Desktop / TV, état principal chargé

## Général

**Entrée du focus =>** bouton **Watch now / Resume**  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si encore présent  
**Fallback =>** bouton **Watch now / Resume**  
**Retour global =>** retour à la page précédente  
**Sortie latérale gauche =>** shell latéral si présent

## Apparence du focus

### Bouton principal "Watch now / Resume"
- **Focus =>** contour blanc 
- c’est l’action principale de la page, le focus doit être le plus évident ici

### Boutons ronds du hero
- **Back / Tracking / More / Change version / Favorite =>** halo ou fond gris renforcé
- le focus doit rester très lisible sur l’image du hero

### Item cast
- **Focus =>** card entière mise en avant
- idéalement : contour accent + légère élévation / agrandissement subtil

### Onglet de saison
- **Focus =>** indicateur / soulignement accent visible
- l’onglet actif et l’onglet focusé doivent rester distinguables

### Épisode
- **Focus =>** card ou ligne entière mise en avant
- sur desktop : card entière focusée avec contour clair

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Watch now / Resume**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Tracking** si visible, sinon bouton **More**

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Tracking" (si visible)

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Watch now / Resume**  
**LEFT ← =>** bouton **Back**  
**RIGHT → =>** bouton **More**

### Validation / action

**CLICK / OK / ENTER =>** active / désactive le suivi de la série

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "More"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Watch now / Resume**  
**LEFT ← =>** bouton **Tracking** si visible, sinon bouton **Back**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le menu d’options

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Watch now / Resume"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** premier item de **Cast** si présent, sinon premier **onglet de saison**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Change version** puis **Favorite**

### Validation / action

**CLICK / OK / ENTER =>** lance la lecture ou reprend au bon épisode

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Change version"

### Comportement attendu par action

**UP ↑ =>** bouton **More**  
**DOWN ↓ =>** premier item de **Cast** si présent, sinon premier **onglet de saison**  
**LEFT ← =>** bouton **Watch now / Resume**  
**RIGHT → =>** bouton **Favorite**

### Validation / action

**CLICK / OK / ENTER =>** ouvre la sélection de version

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Favorite"

### Comportement attendu par action

**UP ↑ =>** bouton **More**  
**DOWN ↓ =>** premier item de **Cast** si présent, sinon premier **onglet de saison**  
**LEFT ← =>** bouton **Change version**  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ajoute / retire des favoris

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Item "Cast"

### Comportement attendu par action

**UP ↑ =>** action hero la plus proche, sinon bouton **Watch now / Resume**  
**DOWN ↓ =>** premier **onglet de saison** si présent, sinon premier **épisode** visible  
**LEFT ← =>** item cast à gauche si présent, sinon shell latéral si présent  
**RIGHT → =>** item cast à droite si présent, sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche de la personne

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Onglet de saison

### Comportement attendu par action

**UP ↑ =>** item cast le plus proche, sinon action hero la plus proche  
**DOWN ↓ =>** premier épisode de la saison active  
**LEFT ← =>** onglet précédent si présent, sinon shell latéral si présent  
**RIGHT → =>** onglet suivant si présent, sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** active l’onglet de saison

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Épisode

### Comportement attendu par action

**UP ↑ =>** épisode au-dessus si layout vertical, sinon onglet de saison  
**DOWN ↓ =>** épisode en dessous si layout vertical, sinon bloqué  
**LEFT ← =>** épisode précédent si layout horizontal, sinon bloqué
**RIGHT → =>** épisode suivant si layout horizontal, sinon bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la lecture de l’épisode sélectionné

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
- le spinner / écran de chargement doit rester purement informatif
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

# Cas 5 — Contenu restreint / verrou parental

## Général

**Entrée du focus =>** bouton **Déverrouiller (PIN)**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Déverrouiller (PIN)**  
**Retour global =>** retour à la page précédente

## Apparence du focus

- le bouton **Déverrouiller (PIN)** doit être l’action principale évidente
- le message de restriction reste informatif
- le focus doit être très visible sur le bouton

## Bouton "Déverrouiller (PIN)"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la feuille / dialog PIN

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
- les actions possibles comprennent au minimum :
  - **Refresh metadata**
  - **Activer / Désactiver le mode spoiler**
  - **Add to list**
  - **Mark seen / Mark unseen** si disponible
  - **Report problem**

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

# Cas 7 — Sélection de version ouverte

## Général

**Entrée du focus =>** première option disponible  
**Mémoire du focus au retour =>** oui, retour sur le bouton **Change version**  
**Fallback =>** première option disponible  
**Retour global =>** ferme la sélection

## Apparence du focus

- l’option focusée doit être surlignée ligne entière
- l’option déjà sélectionnée et l’option focusée doivent rester distinguables
- le bouton **Cancel** doit être visible comme action secondaire

## Option de version

### Comportement attendu par action

**UP ↑ =>** option précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** option suivante si elle existe, sinon bouton **Cancel**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** valide la version choisie

### Retour

**BACK / ESC =>** ferme la sélection

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière option  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ferme la sélection

### Retour

**BACK / ESC =>** ferme la sélection

---

# Cas 8 — Dialog / sheet "Ajouter à une liste"

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

**CLICK / OK / ENTER =>** ajoute la série à la playlist sélectionnée

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