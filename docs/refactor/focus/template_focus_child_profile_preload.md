# FICHE : Child Profile Preload

## 1) Contexte
**Page :** Child Profile Preload  
**Couverture :** États de préchargement du profil enfant

---

# Cas 1 — Préchargement en cours, sans bouton "Passer"

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** aucun  
**Retour global =>** bloqué si le flux ne doit pas être interrompu

## Apparence du focus

- aucun élément ne doit paraître focusable
- le spinner, la progression et les compteurs doivent rester purement informatifs
- aucun halo, contour ou état actif ne doit suggérer une interaction

## Zone de préchargement

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

# Cas 2 — Préchargement en cours, avec bouton "Passer"

## Général

**Entrée du focus =>** bouton **Passer**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Passer**  
**Retour global =>** bloqué

## Apparence du focus

- le focus doit être porté uniquement par le bouton **Passer**
- le bouton focusé doit être clairement identifiable par un **contour**, un **halo** ou une **mise en avant du fond**
- les éléments de progression restent non interactifs et ne doivent jamais sembler focusables

## Bouton "Passer"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** passe cette étape de préchargement  

### Retour

**BACK / ESC =>** bloqué  

---

# Cas 3 — Tout début, avant premier progrès affiché

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** aucun  
**Retour global =>** bloqué

## Apparence du focus

- aucun élément ne doit recevoir de focus visible
- l’écran doit rester perçu comme un état passif d’initialisation
- le spinner initial ne doit pas suggérer une action possible

## Zone d’initialisation

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action  

### Retour

**BACK / ESC =>** bloqué  