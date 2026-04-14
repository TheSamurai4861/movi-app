# FICHE : Welcome Source Select

## 1) Contexte
**Page :** Welcome Source Select  
**Couverture :** Header, états de liste, état vide, état recovery

---

# Cas 1 — État normal avec liste de sources

## Général

**Entrée du focus =>** première source de la liste  
**Mémoire du focus au retour =>** oui, sur la dernière source focusée si elle existe encore  
**Fallback =>** première source de la liste  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Source
- **Focus =>** bordure accentuée autour de la card
- **Source active =>** bordure blanche autour de la card
- **Source active + focusée =>** la card doit montrer à la fois l’état actif et l’état focusé, sans ambiguïté

### Bouton retour
- **Focus =>** fond gris moyen ou halo clair autour du bouton

### Boutons d’action
- non applicables dans ce cas hors bouton retour

## Bouton retour

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première source de la liste  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Source

### Comportement attendu par action

**UP ↑ =>** source au-dessus si elle existe, sinon bouton **Retour**  
**DOWN ↓ =>** source suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** sélectionne / active la source  

### Retour

**BACK / ESC =>** bouton **Retour**  

---

# Cas 2 — État vide, aucune source

## Général

**Entrée du focus =>** bouton **Ajouter une source**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Ajouter une source**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** fond gris moyen ou halo clair autour du bouton

### Bouton "Ajouter une source"
- **Focus =>** bordure blanche autour du bouton
- le bouton doit être perçu comme l’action principale de l’écran vide

## Bouton retour

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Ajouter une source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Ajouter une source"

### Comportement attendu par action

**UP ↑ =>** bouton **Retour**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le flux d’ajout de source  

### Retour

**BACK / ESC =>** bouton **Retour**  

---

# Cas 3 — État avec bannière de recovery

## Général

**Entrée du focus =>** bouton **Retry**  
**Mémoire du focus au retour =>** oui, sur la dernière source focusée si elle existe encore ; sinon bouton **Retry**  
**Fallback =>** bouton **Retry**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Source
- **Focus =>** bordure accentuée autour de la card
- **Source active =>** bordure blanche autour de la card
- **Source active + focusée =>** double lecture visuelle claire entre actif et focus

### Bouton retour
- **Focus =>** fond gris moyen ou halo clair autour du bouton

### Bouton "Retry"
- **Focus =>** bordure blanche autour du bouton
- le bouton doit apparaître comme l’action principale liée à l’état recovery

## Bouton retour

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

## Bouton "Retry"

### Comportement attendu par action

**UP ↑ =>** bouton **Retour**  
**DOWN ↓ =>** première source si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance l’action de recovery  

### Retour

**BACK / ESC =>** bouton **Retour**  

---

## Source

### Comportement attendu par action

**UP ↑ =>** source au-dessus si elle existe, sinon bouton **Retry**  
**DOWN ↓ =>** source suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** sélectionne / active la source  

### Retour

**BACK / ESC =>** bouton **Retour**  