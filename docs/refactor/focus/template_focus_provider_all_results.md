# FICHE : Provider All Results

## 1) Contexte
**Page :** Provider All Results  
**Couverture :** Header de sous-page, bouton retour, grille de médias, état vide, chargement initial, chargement supplémentaire

---

# Cas 1 — Résultats chargés avec grille

## Général

**Entrée du focus =>** première card de la grille  
**Mémoire du focus au retour =>** oui, sur la dernière card focusée si elle existe encore  
**Fallback =>** première card de la grille  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Card média
- **Focus =>** card entière mise en avant
- idéalement :
  - contour lumineux / accent visible
  - légère élévation
  - agrandissement subtil
- une seule card doit paraître active à la fois

### Bouton primaire
- **Focus =>** **contour blanc**

### Bouton icône
- **Focus =>** **fond grisé**
- **pas de contour**

### État loading-more
- le spinner de chargement supplémentaire reste informatif
- il ne doit jamais sembler focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première card de la grille  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Première card de la grille

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** card située en dessous si elle existe, sinon déclenche éventuellement le chargement supplémentaire puis reste dans la grille  
**LEFT ← =>** bloqué  
**RIGHT → =>** card suivante si elle existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du média sélectionné  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Card intermédiaire de la grille

### Comportement attendu par action

**UP ↑ =>** card la plus proche au-dessus si elle existe, sinon bouton **Back**  
**DOWN ↓ =>** card la plus proche en dessous si elle existe, sinon déclenche éventuellement le chargement supplémentaire puis reste sur place  
**LEFT ← =>** card précédente si elle existe, sinon bloqué  
**RIGHT → =>** card suivante si elle existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du média sélectionné  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Dernière card d’une ligne

### Comportement attendu par action

**UP ↑ =>** card la plus proche au-dessus  
**DOWN ↓ =>** card la plus proche en dessous si elle existe, sinon déclenche éventuellement le chargement supplémentaire puis reste sur place  
**LEFT ← =>** card précédente  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du média sélectionné  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Dernière card de la grille visible

### Comportement attendu par action

**UP ↑ =>** card la plus proche au-dessus  
**DOWN ↓ =>** si d’autres résultats existent, lance le chargement supplémentaire puis conserve le focus dans la grille ; sinon bloqué  
**LEFT ← =>** card précédente si elle existe, sinon bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du média sélectionné  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 2 — Chargement initial

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Zone de chargement
- le spinner est purement informatif
- aucun élément du contenu ne doit sembler focusable

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 3 — État vide

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Message vide
- le message “aucun résultat” reste purement informatif
- aucun élément du corps de page ne doit sembler interactif

### Bouton primaire éventuel
- si un CTA est ajouté plus tard
- **Focus =>** **contour blanc**

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 4 — Chargement supplémentaire en bas de grille

## Général

**Entrée du focus =>** conserve le focus sur la dernière card active  
**Mémoire du focus au retour =>** oui  
**Fallback =>** dernière card active  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Card active
- **Focus =>** card entière mise en avant
- le focus ne doit pas sauter sur le spinner

### Spinner de chargement supplémentaire
- purement informatif
- non focusable
- ne doit pas casser la lisibilité du focus sur la card active

## Dernière card active

### Comportement attendu par action

**UP ↑ =>** card au-dessus si elle existe  
**DOWN ↓ =>** si le chargement est en cours, reste sur la card active ; puis une fois les nouveaux items chargés, permet la navigation vers les nouvelles cards  
**LEFT ← =>** card précédente si elle existe  
**RIGHT → =>** bloqué si elle est en bord droit  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du média sélectionné  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 5 — Erreur de chargement ponctuelle avec snackbar

## Général

**Entrée du focus =>** conserve le focus courant  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Back** si aucun item n’est présent, sinon première card  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Focus courant
- il doit rester stable malgré l’affichage de la snackbar
- la snackbar ne doit pas prendre le focus

### Snackbar
- purement informative
- non focusable

### Bouton retour
- si aucun item n’est disponible
- **Focus =>** **fond grisé**
- **pas de contour**

## Élément focusé courant

### Comportement attendu par action

**UP ↑ =>** navigation normale selon la zone focusée  
**DOWN ↓ =>** navigation normale selon la zone focusée  
**LEFT ← =>** navigation normale selon la zone focusée  
**RIGHT → =>** navigation normale selon la zone focusée  

### Validation / action

**CLICK / OK / ENTER =>** action normale de l’élément focusé  

### Retour

**BACK / ESC =>** retour à la page précédente  