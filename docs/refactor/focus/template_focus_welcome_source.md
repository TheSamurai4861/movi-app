# FICHE : Welcome Source

## 1) Contexte
**Page :** Welcome Source  
**Couverture :** Sources sauvegardées + bouton refresh + formulaire d’ajout + bouton d’activation + FAQ

---

## 2) Général

**Entrée du focus =>**
- **si des sources sauvegardées existent** : première source sauvegardée
- **si un état erreur est affiché** : bouton **Retry**
- **si aucune source sauvegardée n’existe** : premier input du formulaire, **Nom de la source**

**Mémoire du focus au retour =>** oui, sur le dernier élément interactif encore disponible si possible  
**Fallback =>**
- première source sauvegardée si la liste existe
- sinon bouton **Retry** en cas d’erreur
- sinon input **Nom de la source**

**Retour global =>** bloqué

---

## 3) Apparence du focus

### Source sauvegardée
- **Focus =>** bordure accent autour de la source
- **Source sélectionnée / active =>** état visuel distinct conservé
- **Source sélectionnée + focusée =>** les deux états doivent rester lisibles sans ambiguïté

### Bouton Retry
- **Focus =>** bordure blanche autour du bouton

### Bouton Refresh
- **Focus =>** fond gris moyen ou contour clair bien visible

### Inputs du formulaire
- **Focus =>** contour accentué autour du champ
- le champ focusé doit clairement indiquer qu’il est prêt à être modifié

### Bouton afficher / masquer le mot de passe
- **Focus =>** anneau clair ou fond renforcé sur l’icône/bouton

### Bouton d’activation
- **Focus =>** bordure blanche autour du bouton
- le bouton doit apparaître comme l’action principale du formulaire

### FAQ
- **Focus =>** surbrillance légère ou contour discret sur la zone focusable
- pour l’instant, la FAQ ne doit pas sembler actionnable si elle ne fait rien réellement

---

## 4) ListTile d’une source sauvegardée

### Comportement attendu par action

**UP ↑ =>** source sauvegardée au-dessus si elle existe, sinon bouton **Refresh**  
**DOWN ↓ =>** source sauvegardée en dessous si elle existe, sinon premier input du formulaire d’ajout  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** sélectionne / active la source choisie  

### Retour

**BACK / ESC =>** bloqué  

---

## 5) Bouton Refresh

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première source sauvegardée si elle existe, sinon premier input du formulaire d’ajout  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le rafraîchissement des sources sauvegardées  

### Retour

**BACK / ESC =>** bloqué  

---

## 6) Input du formulaire

### Comportement attendu par action

**UP ↑ =>** dernière source sauvegardée si elle existe, sinon bouton **Refresh**  
**DOWN ↓ =>** input suivant si il existe, sinon bouton **Activer**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué, sauf pour l’input mot de passe où l’on va vers le bouton **afficher / masquer**  

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ  

### Retour

**BACK / ESC =>** bloqué  

---

## 7) Bouton afficher / masquer le mot de passe

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Activer**  
**LEFT ← =>** input mot de passe  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** alterne entre afficher et masquer le mot de passe  

### Retour

**BACK / ESC =>** bloqué  

---

## 8) Bouton d’activation

### Comportement attendu par action

**UP ↑ =>** dernier input du formulaire, ou bouton afficher / masquer si on vient du champ mot de passe  
**DOWN ↓ =>** FAQ  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** lance l’activation de la source  

### Retour

**BACK / ESC =>** bloqué  

---

## 9) FAQ

### Comportement attendu par action

**UP ↑ =>** bouton **Activer**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action pour l’instant  

### Retour

**BACK / ESC =>** bloqué  