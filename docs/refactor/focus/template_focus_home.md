# FICHE : Home

## 1) Contexte
**Page :** Home  
**Couverture :** Hero, filtres, actions principales, Continue Watching, catégories IPTV

---

# Cas 1 — Home desktop / TV, état principal chargé

## Général

**Entrée du focus =>** bouton **Watch now**  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé de la page si encore présent  
**Fallback =>** bouton **Watch now**  
**Retour global =>** retour vers l’icône **Home** du shell latéral

## Apparence du focus

- le focus doit être **très visible** sur fond hero
- les **filtres** focusés doivent être distingués à la fois de l’état actif et de l’état inactif
- le bouton **Watch now** doit avoir un focus principal évident : contour, halo, fond renforcé
- le bouton **Fav** doit garder un anneau de focus net malgré sa petite taille
- les **cards** doivent être focusées via la **carte entière** : contour lumineux, légère élévation ou agrandissement subtil
- la card **See all** doit être perçue comme une vraie destination interactive, pas comme une card média classique

---

## Filtres Movies / Series

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Watch now**  
**LEFT ← =>** autre filtre si présent à gauche, sinon icône **Home** du menu latéral  
**RIGHT → =>** autre filtre si présent à droite, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** change le filtre actif et recharge le hero / contenu associé  

### Retour

**BACK / ESC =>** retour vers l’icône **Home** du shell latéral  

---

## Bouton "Watch now"

### Comportement attendu par action

**UP ↑ =>** premier filtre  
**DOWN ↓ =>** première card de **Continue Watching**, ou premier élément de la section suivante disponible  
**LEFT ← =>** icône **Home** du menu latéral  
**RIGHT → =>** bouton **Fav**  

### Validation / action

**CLICK / OK / ENTER =>** lance l’action principale du hero  

### Retour

**BACK / ESC =>** retour vers l’icône **Home** du shell latéral  

---

## Bouton "Fav"

### Comportement attendu par action

**UP ↑ =>** premier filtre  
**DOWN ↓ =>** première card de **Continue Watching**, ou premier élément de la section suivante disponible  
**LEFT ← =>** bouton **Watch now**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ajoute / retire des favoris  

### Retour

**BACK / ESC =>** retour vers l’icône **Home** du shell latéral  

---

## Card "Continue Watching" / Card de catégorie

### Comportement attendu par action

**UP ↑ =>** card la plus proche dans la rangée au-dessus, sinon si première rangée bouton **Watch now**  
**DOWN ↓ =>** card la plus proche dans la catégorie suivante, sinon bloqué  
**LEFT ← =>** card à gauche si elle existe, sinon icône **Home** du menu latéral  
**RIGHT → =>** card à droite si elle existe, sinon bloqué ou **See all** si elle est immédiatement après  

### Validation / action

**CLICK / OK / ENTER =>** ouvre l’élément correspondant  

### Retour

**BACK / ESC =>** retour vers l’icône **Home** du shell latéral  

---

## Card "See all"

### Comportement attendu par action

**UP ↑ =>** card la plus proche dans la rangée au-dessus, sinon si première rangée bouton **Watch now**  
**DOWN ↓ =>** card la plus proche dans la catégorie suivante, sinon bloqué  
**LEFT ← =>** dernière card média de la rangée  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la vue complète de la catégorie  

### Retour

**BACK / ESC =>** retour vers l’icône **Home** du shell latéral  

---

# Cas 2 — Continue Watching verrouillé par Premium

## Général

**Entrée du focus =>** bouton **Watch now**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Watch now**  
**Retour global =>** retour vers l’icône **Home** du shell latéral

## Apparence du focus

- le focus du CTA **Découvrir Premium** doit en faire l’action principale de la section verrouillée
- visuellement, il doit être plus clair qu’un simple texte d’info
- le focus des autres éléments de la page reste inchangé
- la carte premium ou le bloc premium ne doit pas sembler focusable en dehors de son bouton CTA

---

## Bouton "Découvrir Premium"

### Comportement attendu par action

**UP ↑ =>** bouton **Watch now**  
**DOWN ↓ =>** première card de la première catégorie disponible sous cette section  
**LEFT ← =>** icône **Home** du menu latéral  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre l’offre / écran Premium  

### Retour

**BACK / ESC =>** retour vers l’icône **Home** du shell latéral  