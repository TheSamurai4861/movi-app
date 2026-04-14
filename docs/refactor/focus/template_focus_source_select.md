# FICHE : IPTV Source Select

## 1) Contexte
**Page :** IPTV Source Select  
**Couverture :** Header de sous-page, bouton retour, liste de sources activables, états vide / chargement / erreur, overlay de changement de source

## 2) Audit UI réel avant fiche

### Structure visible confirmée
La page affiche :

- un **header** avec :
  - bouton **Retour**
  - titre de sous-page
- une grande zone de contenu qui montre :
  - soit un **spinner** de chargement
  - soit un **message d’erreur texte**
  - soit un **message vide** centré
  - soit une **liste de sources**
- pendant l’activation d’une source :
  - un **overlay pleine page** semi-opaque avec **spinner**

### Point important
Sur cette page, les vrais éléments focusables visibles sont :

- le **bouton Retour**
- les **items de la liste de sources** quand la liste existe

Il n’y a ici :
- **pas de bouton Retry visible**
- **pas de bouton Ajouter une source**
- **pas de bannière recovery**
- **pas d’action trailing visible dans cette page**

---

# Cas 1 — Liste de sources chargée

## Général

**Entrée du focus =>** première source de la liste  
**Mémoire du focus au retour =>** oui, sur la dernière source focusée si elle existe encore  
**Fallback =>** première source de la liste, sinon bouton **Retour**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Source
- **Focus =>** bordure accent autour de l’item / de la ligne
- la **source sélectionnée / active** doit conserver un état visuel distinct
- la **source sélectionnée + focusée** doit rester lisible sans ambiguïté

### Liste
- une seule source doit paraître active à la fois
- la navigation doit rester simple et verticale

---

## Bouton "Back"

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

## Première source

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** source suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active cette source ; si c’est déjà la source active, fermeture de la page avec succès

### Retour

**BACK / ESC =>** bouton **Back**

---

## Source intermédiaire

### Comportement attendu par action

**UP ↑ =>** source précédente  
**DOWN ↓ =>** source suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active cette source

### Retour

**BACK / ESC =>** bouton **Back**

---

## Dernière source

### Comportement attendu par action

**UP ↑ =>** source précédente  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active cette source

### Retour

**BACK / ESC =>** bouton **Back**

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

### Spinner
- purement informatif
- non focusable

### Corps de page
- aucun autre élément ne doit sembler interactif

---

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

# Cas 3 — Erreur simple

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Message d’erreur
- purement informatif
- non focusable

### Corps de page
- aucun bouton de récupération visible dans cette page
- aucun autre élément ne doit sembler interactif

---

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

# Cas 4 — État vide, aucune source

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
- texte centré purement informatif
- non focusable

### Corps de page
- aucun CTA visible
- aucun autre élément ne doit sembler interactif

---

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

# Cas 5 — Activation d’une source en cours

## Général

**Entrée du focus =>** conserve le focus sur la source qui a lancé l’action si possible, mais l’overlay bloque toute nouvelle interaction  
**Mémoire du focus au retour =>** oui, une fois l’overlay disparu  
**Fallback =>** source active ou première source  
**Retour global =>** bloqué tant que le changement est en cours

## Apparence du focus

### Overlay de chargement
- voile sombre semi-opaque pleine page
- spinner centré
- doit visuellement bloquer l’interface

### Éléments derrière l’overlay
- ne doivent plus paraître activables pendant l’opération
- le focus résiduel ne doit pas donner l’impression qu’une action est possible

---

## Overlay de changement

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action

### Retour

**BACK / ESC =>** bloqué