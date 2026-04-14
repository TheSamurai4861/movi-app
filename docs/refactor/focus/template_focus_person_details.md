# FICHE : Person Detail

## 1) Contexte
**Page :** Person Detail  
**Couverture :** Hero, action principale, favori, biographie, filmographie films + séries

---

# Cas 1 — Desktop / TV, état principal chargé

## Général

**Entrée du focus =>** bouton **Play Randomly**  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si encore présent  
**Fallback =>** bouton **Play Randomly**  
**Retour global =>** retour à la page précédente  
**Sortie latérale gauche =>** shell latéral si présent

## Apparence du focus

### Bouton principal "Play Randomly"
- **Focus =>** contour blanc + fond renforcé
- c’est l’action principale de la page, le focus doit être le plus évident ici

### Bouton "Back"
- **Focus =>** fond gris clair / halo discret autour du bouton rond
- le focus doit rester visible même sur le hero

### Bouton "Favorite"
- **Focus =>** bordure accent + fond grisé renforcé sur le bouton
- l’état favori et l’état focusé doivent rester distinguables

### Bouton "Expand / Collapse" de la biographie
- **Focus =>** pill / bouton avec fond renforcé

### Film / Série dans la filmographie
- **Focus =>** card entière mise en avant
- idéalement : contour accent + légère élévation / agrandissement subtil

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Play Randomly**  
**LEFT ← =>** shell latéral si présent, sinon bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Play Randomly"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bouton **Expand / Collapse** de la biographie si présent, sinon premier film  
**LEFT ← =>** bloqué
**RIGHT → =>** bouton **Favorite**  

### Validation / action

**CLICK / OK / ENTER =>** ouvre aléatoirement un film ou une série de la personne  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Favorite"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Play Randomly**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ajoute / retire la personne des favoris  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Expand / Collapse" de la biographie

### Comportement attendu par action

**UP ↑ =>** bouton **Play Randomly**  
**DOWN ↓ =>** premier film  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** étend ou replie la biographie  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Premier film

### Comportement attendu par action

**UP ↑ =>** bouton **Expand / Collapse** si présent, sinon bouton **Play Randomly**  
**DOWN ↓ =>** première série  
**LEFT ← =>** bloqué  
**RIGHT → =>** film suivant  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du film  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Film de la filmographie

### Comportement attendu par action

**UP ↑ =>** reste dans la rangée films ; pour le premier film, remonte à **Expand / Collapse** si présent, sinon **Play Randomly**  
**DOWN ↓ =>** série la plus proche dessous si présente, sinon bloqué  
**LEFT ← =>** film précédent si présent, sinon bloqué  
**RIGHT → =>** film suivant si présent, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du film  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Première série

### Comportement attendu par action

**UP ↑ =>** premier film  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** série suivante  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche de la série  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Série de la filmographie

### Comportement attendu par action

**UP ↑ =>** film le plus proche au-dessus  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** série précédente si présente, sinon bloqué  
**RIGHT → =>** série suivante si présente, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche de la série  

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
- le spinner / overlay de chargement doit rester purement informatif
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

# Cas 4 — Erreur avec bouton "Retry"

## Général

**Entrée du focus =>** bouton **Retry**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Retry**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton "Retry"
- **Focus =>** bordure blanche autour du bouton
- le bouton doit être clairement perçu comme l’action principale de récupération

## Bouton "Retry"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement des métadonnées de la personne  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 5 — Données absentes / personne introuvable

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non  
**Fallback =>** aucun  
**Retour global =>** retour à la page précédente

## Apparence du focus

- le message d’absence de données doit rester purement informatif
- aucun élément de l’écran ne doit sembler interactif

## Zone informative

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action  

### Retour

**BACK / ESC =>** retour à la page précédente  