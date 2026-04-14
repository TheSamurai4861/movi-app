# FICHE : Category

## 1) Contexte
**Page :** Category  
**Couverture :** Header + états de contenu + grille média

---

# Cas 1 — Chargement initial

## Général

**Entrée du focus =>** bouton **Retour**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Retour**

## Apparence du focus

- le focus est porté uniquement par le **bouton Retour**
- le bouton focusé doit être clairement visible via un **anneau**, un **contour** ou une **mise en avant du fond**
- le spinner et la zone de chargement ne doivent pas donner l’impression d’être interactifs

## Bouton Retour

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

# Cas 2 — Erreur avec bouton Retry

## Général

**Entrée du focus =>** bouton **Retry**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Retry**

## Apparence du focus

- le focus d’entrée doit aller sur **Retry**
- le bouton **Retry** doit apparaître comme l’action principale
- le **bouton Retour** garde un focus clair mais plus secondaire
- le message d’erreur reste purement informatif et ne doit pas sembler focusable

## Bouton Retour

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Retry**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton Retry

### Comportement attendu par action

**UP ↑ =>** bouton **Retour**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 3 — État vide

## Général

**Entrée du focus =>** bouton **Retour**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Retour**

## Apparence du focus

- le focus est porté uniquement par le **bouton Retour**
- le message vide doit rester non interactif
- aucun élément du corps de page ne doit suggérer une action

## Bouton Retour

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

# Cas 4 — Contenu chargé avec grille média

## Général

**Entrée du focus =>** première card de la grille  
**Mémoire du focus au retour =>** oui, sur la dernière card focusée si elle existe encore  
**Fallback =>** première card de la grille  
**Retour global =>** retour à la page précédente

## Apparence du focus

- la **card focusée** doit être clairement mise en avant
- le focus sur card doit idéalement utiliser :
  - un **contour lumineux**
  - une **élévation légère**
  - un **agrandissement subtil**
- le **bouton Retour** garde un focus très lisible mais distinct du focus des cards
- une seule card doit sembler active à la fois

## Bouton Retour

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première card  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Card

### Comportement attendu par action

**UP ↑ =>** card au-dessus si elle existe, sinon bouton **Retour**  
**DOWN ↓ =>** card en dessous si elle existe, sinon bloqué  
**LEFT ← =>** card à gauche si elle existe, sinon bloqué  
**RIGHT → =>** card à droite si elle existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre l’élément média correspondant  

### Retour

**BACK / ESC =>** retour à la page précédente  