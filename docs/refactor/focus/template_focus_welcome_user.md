# FICHE : Welcome User

## 1) Contexte
**Page :** Welcome User  
**Couverture :** Sélection de profil existant + création du premier profil

---

# CAS 1 — Des profils existent déjà

## Général

**Entrée du focus =>** premier avatar sélectionné  
**Mémoire du focus au retour =>** oui, sur le dernier avatar focusé ou sélectionné si encore présent  
**Fallback =>** premier avatar disponible  
**Retour global =>** bloqué

## Apparence du focus

### Avatar
- **Focus =>** bordure blanche autour de l’avatar focusé
- **Sélection =>** l’avatar sélectionné conserve une mise en avant visuelle persistante
- **Sélection + focus =>** les deux états doivent rester lisibles sans ambiguïté
- l’avatar focusé doit être immédiatement identifiable comme cible active de navigation

## Avatar

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** avatar à gauche si il existe, sinon bloqué  
**RIGHT → =>** avatar à droite si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** sélectionne l’avatar  

### Apparence après sélection

- bordure blanche autour de l’avatar sélectionné tant qu’il reste sélectionné

### Retour

**BACK / ESC =>** bloqué  

---

# CAS 2 — Aucun profil n’existe encore

## Général

**Entrée du focus =>** input **Nom d’utilisateur**  
**Mémoire du focus au retour =>** non  
**Fallback =>** input **Nom d’utilisateur**  
**Retour global =>** bloqué

## Apparence du focus

### Input "Nom d’utilisateur"
- **Focus =>** bordure de couleur accent autour de l’input
- le champ doit clairement montrer qu’il est prêt à recevoir une saisie

### Bouton "Continue"
- **Focus =>** contour clair ou fond renforcé bien visible
- le bouton doit apparaître comme l’action principale après la saisie

## Input "Nom d’utilisateur"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Continue**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active l’input  
**Note =>** l’input est déjà actif à l’arrivée sur la page

### Retour

**BACK / ESC =>** bloqué  

---

## Bouton "Continue"

### Comportement attendu par action

**UP ↑ =>** input **Nom d’utilisateur**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** valide le formulaire et continue le flux  

### Retour

**BACK / ESC =>** bloqué  