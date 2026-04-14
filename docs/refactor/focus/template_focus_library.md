# FICHE : Library

## 1) Contexte
**Page :** Library  
**Couverture :** Header, filtres, recherche, CTA premium, grille de playlists, dialog de création

---

# Cas 1 — Desktop / TV, état principal avec grille

## Général

**Entrée du focus =>** première playlist de la grille  
**Mémoire du focus au retour =>** oui, sur la dernière playlist ou le dernier contrôle interactif utilisé si encore présent  
**Fallback =>** première playlist de la grille  
**Retour global =>** retour vers l’icône **Library** du shell latéral

## Apparence du focus

- la **playlist focusée** doit être mise en avant par la **carte entière**
- le focus sur grille doit être très visible : contour lumineux, légère élévation ou agrandissement subtil
- les **pills de filtre** doivent distinguer clairement :
  - l’état actif
  - l’état focusé
  - l’état actif + focusé
- le **champ de recherche** focusé doit montrer clairement qu’il entre en mode saisie
- le **bouton Add playlist** doit rester identifiable comme une action secondaire forte
- le **bouton Premium** doit apparaître comme CTA principal dans sa zone, sans rendre tout le bloc premium focusable

---

## Playlist

### Comportement attendu par action

**UP ↑ =>** playlist au-dessus si elle existe, sinon premier filtre **Playlists**  
**DOWN ↓ =>** playlist en dessous si elle existe, sinon bloqué  
**LEFT ← =>** playlist à gauche si elle existe, sinon icône **Library** du shell latéral  
**RIGHT → =>** playlist à droite si elle existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la playlist sélectionnée  

### Retour

**BACK / ESC =>** retour vers l’icône **Library** du shell latéral  

---

## Pill de filtre

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première playlist de la grille si elle existe, sinon bloqué  
**LEFT ← =>** filtre précédent si présent, sinon icône **Library** du shell latéral  
**RIGHT → =>** filtre suivant si présent, sinon champ de recherche s’il est visible et focusable  

### Validation / action

**CLICK / OK / ENTER =>** applique le filtre sélectionné  

### Retour

**BACK / ESC =>** retour vers l’icône **Library** du shell latéral  

---

## Bouton "Add playlist"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première playlist de la grille si elle existe, sinon bloqué  
**LEFT ← =>** champ de recherche  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le dialog de création de playlist  

### Retour

**BACK / ESC =>** retour vers l’icône **Library** du shell latéral  

---

## Input search

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première playlist de la grille si elle existe, sinon bloqué  
**LEFT ← =>** dernier filtre  
**RIGHT → =>** bouton **Add playlist**  

### Validation / action

**CLICK / OK / ENTER =>** active la recherche / place le curseur dans l’input  

### Retour

**BACK / ESC =>** retour vers l’icône **Library** du shell latéral  

---

## Bouton Premium

### Comportement attendu par action

**UP ↑ =>** premier filtre  
**DOWN ↓ =>** première playlist de la grille si elle existe, sinon bloqué  
**LEFT ← =>** icône **Library** du shell latéral  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre l’écran ou l’offre Premium  

### Retour

**BACK / ESC =>** retour vers l’icône **Library** du shell latéral  

---

# Cas 2 — Dialog "Créer une playlist"

## Général

**Entrée du focus =>** champ **Nom de playlist**  
**Mémoire du focus au retour =>** oui, retour sur le bouton **Add playlist** après fermeture  
**Fallback =>** champ **Nom de playlist**  
**Retour global =>** ferme le dialog

## Apparence du focus

- le dialog doit prendre la priorité visuelle complète
- le fond derrière doit paraître inactif
- le **champ texte** focusé doit clairement montrer l’état de saisie
- les boutons **Cancel** et **Create** doivent avoir un focus distinct, lisible et stable
- **Create** peut apparaître comme l’action principale, mais **Cancel** doit rester très facilement repérable

---

## Champ "Nom de playlist"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Create**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active l’input / permet la saisie  

### Retour

**BACK / ESC =>** ferme le dialog  

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** champ **Nom de playlist**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Create**  

### Validation / action

**CLICK / OK / ENTER =>** annule et ferme le dialog  

### Retour

**BACK / ESC =>** ferme le dialog  

---

## Bouton "Create"

### Comportement attendu par action

**UP ↑ =>** champ **Nom de playlist**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Cancel**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** crée la playlist si la saisie est valide  

### Retour

**BACK / ESC =>** ferme le dialog  