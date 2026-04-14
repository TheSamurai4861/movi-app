# FICHE : Welcome Source Loading

## 1) Contexte
**Page :** Welcome Source Loading  
**Couverture :** États de chargement et d’erreur liés au chargement d’une source

---

# Cas 1 — Chargement en cours

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** aucun  
**Retour global =>** bloqué

## Apparence du focus

- aucun élément ne doit paraître focusable
- le logo, le spinner et le message de statut doivent rester purement informatifs
- la surface de chargement ne doit pas suggérer qu’une action est possible
- aucun halo, contour ou surbrillance ne doit apparaître dans cet état

## Zone de chargement

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action  

### Retour

**BACK / ESC =>** bloqué  

---

# Cas 2 — Erreur avec seulement "Réessayer"

## Général

**Entrée du focus =>** bouton **Réessayer**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Réessayer**  
**Retour global =>** bloqué

## Apparence du focus

- le focus doit être porté uniquement par le bouton **Réessayer**
- le bouton focusé doit apparaître comme l’action principale de l’écran
- le message d’erreur reste informatif et non focusable
- le focus doit être très lisible, avec contour, halo ou mise en avant du fond

## Bouton "Réessayer"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement de la source  

### Retour

**BACK / ESC =>** bloqué  

---

# Cas 3 — Erreur avec "Réessayer" + "Choisir une autre source"

## Général

**Entrée du focus =>** bouton **Réessayer**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Réessayer**  
**Retour global =>** bloqué

## Apparence du focus

- les deux boutons doivent être clairement identifiables comme interactifs
- **Réessayer** doit paraître comme l’action principale
- **Choisir une autre source** doit apparaître comme l’action secondaire
- le focus doit se déplacer proprement entre les deux boutons, sans ambiguïté
- le message d’erreur reste non focusable

## Bouton "Réessayer"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Choisir une autre source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement de la source  

### Retour

**BACK / ESC =>** bloqué  

---

## Bouton "Choisir une autre source"

### Comportement attendu par action

**UP ↑ =>** bouton **Réessayer**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la sélection d’une autre source  

### Retour

**BACK / ESC =>** bloqué  