# FICHE : App Update Blocked Screen

## 1) Contexte
**Page / Widget :** App Update Blocked Screen  
**Couverture :** Écran bloquant de mise à jour, résumé de version, bouton d’ouverture du store, bouton retry

## 2) Audit UI réel avant fiche

### Structure visible confirmée
Le widget affiche :

- une page **plein écran centrée**
- une **icône système update**
- un **titre**
- un **texte descriptif**
- un bloc **résumé de version**
  - version installée
  - version minimale si présente
  - dernière version si présente
  - plateforme
- un bouton principal **Ouvrir la mise à jour** seulement si `decision.updateUrl != null`
- un bouton texte **Réessayer** toujours visible

### Point important
Il n’y a ici **pas de bouton retour**, **pas de shell**, **pas d’autre navigation latérale**.  
Les seuls éléments réellement interactifs visibles sont :

- **Ouvrir la mise à jour** si disponible
- **Réessayer**

Le reste est purement informatif.

---

# Cas 1 — Bouton store visible + bouton Retry

## Général

**Entrée du focus =>** bouton **Ouvrir la mise à jour**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Ouvrir la mise à jour**  
**Retour global =>** bloqué

## Apparence du focus

### Bouton primaire "Ouvrir la mise à jour"
- c’est un `MoviPrimaryButton`
- **Focus => contour blanc**
- il doit être perçu comme l’action principale de l’écran

### Bouton texte "Réessayer"
- **Focus =>** texte / zone du bouton mise en avant
- pas un bouton primaire
- doit rester clairement focusable, mais moins dominant visuellement

### Bloc résumé de version
- purement informatif
- non focusable

### Titre / description / icône
- purement informatifs
- non focusables

---

## Bouton "Ouvrir la mise à jour"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Réessayer**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre le store / la page de mise à jour

### Retour

**BACK / ESC =>** bloqué

---

## Bouton "Réessayer"

### Comportement attendu par action

**UP ↑ =>** bouton **Ouvrir la mise à jour**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** relance la vérification de mise à jour

### Retour

**BACK / ESC =>** bloqué

---

# Cas 2 — Pas de bouton store, seulement Retry

## Général

**Entrée du focus =>** bouton **Réessayer**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Réessayer**  
**Retour global =>** bloqué

## Apparence du focus

### Bouton "Réessayer"
- **Focus =>** texte / zone du bouton mise en avant
- il devient la seule action disponible à l’écran

### Bloc résumé de version
- non focusable

### Titre / description / icône
- non focusables

---

## Bouton "Réessayer"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** relance la vérification de mise à jour

### Retour

**BACK / ESC =>** bloqué

---

# Cas 3 — Ouverture du store en cours

## Général

**Entrée du focus =>** conserve le focus sur **Ouvrir la mise à jour** si le bouton reste visible  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Réessayer** si le bouton principal devient inactif  
**Retour global =>** bloqué

## Apparence du focus

### Bouton "Ouvrir la mise à jour"
- passe en état `loading`
- garde sa place visuelle
- si encore focusé :
  - **Focus => contour blanc**
- il ne doit pas suggérer plusieurs activations successives pendant l’ouverture

### Bouton "Réessayer"
- reste secondaire
- peut rester focusable si tu l’autorises pendant l’état d’ouverture

### Reste de l’écran
- informatif
- non focusable

---

## Bouton "Ouvrir la mise à jour" en loading

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Réessayer** si autorisé, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** aucune nouvelle action tant que l’ouverture est en cours

### Retour

**BACK / ESC =>** bloqué