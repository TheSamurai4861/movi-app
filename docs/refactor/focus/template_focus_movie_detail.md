# FICHE : Movie Detail

## 1) Contexte
**Page :** Movie Detail  
**Couverture :** Hero, actions principales, cast, saga, recommandations, overlays d’options

---

# Cas 1 — Desktop / TV, état principal chargé

## Général

**Entrée du focus =>** bouton **Watch now / Resume**  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si encore présent  
**Fallback =>** bouton **Watch now / Resume**  
**Retour global =>** retour à la page précédente  

## Apparence du focus

### Bouton principal "Watch now / Resume"
- **Focus =>** contour blanc
- c’est l’action principale de la page, le focus doit être le plus évident ici

### Boutons ronds / icônes
- **Back / More / Change version / Favorite =>** halo ou fond gris renforcé
- les boutons focusés doivent rester très visibles sur le hero

### Item cast
- **Focus =>** card entière mise en avant
- idéalement : contour accent + légère élévation / agrandissement subtil

### Bouton "Voir la page" de la saga
- **Focus =>** pill / bouton avec fond légèrement teinté 

### Recommandation / film de saga
- **Focus =>** card entière mise en avant avec contour accent

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Watch now / Resume**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **More**

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "More"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Watch now / Resume**  
**LEFT ← =>** bouton **Back**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le menu d’options  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Watch now / Resume"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** item cast le plus proche, sinon première section disponible dessous  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Change version** si visible, sinon bouton **Favorite**

### Validation / action

**CLICK / OK / ENTER =>** lance la lecture  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Change version" (si visible)

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** item cast le plus proche, sinon première section disponible dessous   
**LEFT ← =>** bouton **Watch now / Resume**  
**RIGHT → =>** bouton **Favorite**

### Validation / action

**CLICK / OK / ENTER =>** ouvre la sélection de version / variante  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Favorite"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** item cast le plus proche, sinon première section disponible dessous 
**LEFT ← =>** bouton **Change version** si visible, sinon bouton **Watch now / Resume**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ajoute / retire des favoris  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Item cast

### Comportement attendu par action

**UP ↑ =>** retour vers le bouton principal **Watch now / Resume**  
**DOWN ↓ =>** section suivante la plus proche dessous, sinon bloqué  
**LEFT ← =>** item cast à gauche si présent, sinon bloqué  
**RIGHT → =>** item cast à droite si présent, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche de la personne  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton saga "Voir la page" (si section saga visible)

### Comportement attendu par action

**UP ↑ =>** item cast le plus proche au-dessus  
**DOWN ↓ =>** premier film de la saga  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la page de la saga  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Film dans la section saga

### Comportement attendu par action

**UP ↑ =>** bouton **Voir la page** ou élément le plus proche dans l’en-tête de section  
**DOWN ↓ =>** première recommandation si la section existe dessous, sinon bloqué  
**LEFT ← =>** film précédent de la saga si présent, sinon bloqué  
**RIGHT → =>** film suivant de la saga si présent, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le film sélectionné  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Recommandation

### Comportement attendu par action

**UP ↑ =>** élément le plus proche dans la section au-dessus  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** recommandation précédente si présente, sinon bloqué  
**RIGHT → =>** recommandation suivante si présente, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le film recommandé  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 3 — Chargement

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** aucun  
**Retour global =>** retour à la page précédente

## Apparence du focus

- aucun élément ne doit paraître focusable
- l’overlay de chargement doit rester purement informatif
- le spinner / splash ne doit jamais suggérer une action

## Zone de chargement

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 4 — Erreur simple

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** non  
**Fallback =>** aucun  
**Retour global =>** retour à la page précédente

## Apparence du focus

- le message d’erreur reste informatif
- aucun bouton explicite n’étant visible dans cet état, aucun focus ne doit suggérer une action

## Zone erreur

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** aucune action  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 5 — Contenu restreint / verrou parental

## Général

**Entrée du focus =>** bouton **Déverrouiller (PIN)**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Déverrouiller (PIN)**  
**Retour global =>** retour à la page précédente

## Apparence du focus

- le bouton **Déverrouiller (PIN)** doit être clairement l’action principale
- le message de restriction doit rester purement informatif
- le focus doit être très visible sur le bouton

## Bouton "Déverrouiller (PIN)"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la feuille / dialog PIN  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 6 — Menu "More" ouvert

## Général

**Entrée du focus =>** première action du menu  
**Mémoire du focus au retour =>** oui, retour sur le bouton **More** après fermeture  
**Fallback =>** première action disponible  
**Retour global =>** ferme le menu

## Apparence du focus

- chaque ligne du menu doit recevoir un focus pleine largeur
- l’action focusée doit être immédiatement identifiable
- l’action **Cancel** doit rester secondaire mais clairement focusable

## Action du menu

### Comportement attendu par action

**UP ↑ =>** action précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** action suivante si elle existe, sinon bouton **Cancel**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** exécute l’action sélectionnée  

### Retour

**BACK / ESC =>** ferme le menu  

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière action du menu  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ferme le menu  

### Retour

**BACK / ESC =>** ferme le menu  

---

# Cas 7 — Sélection de version / variante ouverte

## Général

**Entrée du focus =>** première option disponible  
**Mémoire du focus au retour =>** oui, retour sur le bouton **Change version**  
**Fallback =>** première option disponible  
**Retour global =>** ferme la sélection

## Apparence du focus

- l’option focusée doit être surlignée ligne entière
- l’option déjà sélectionnée et l’option focusée doivent rester distinguables
- le bouton **Cancel** doit être visible comme action secondaire

## Option de version

### Comportement attendu par action

**UP ↑ =>** option précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** option suivante si elle existe, sinon bouton **Cancel**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** valide la version et lance la lecture  

### Retour

**BACK / ESC =>** ferme la sélection  

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière option  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ferme la sélection  

### Retour

**BACK / ESC =>** ferme la sélection  

---

# Cas 8 — Dialog / sheet "Ajouter à une liste"

## Général

**Entrée du focus =>** première playlist disponible  
**Mémoire du focus au retour =>** oui, retour sur l’action qui a ouvert le dialog  
**Fallback =>** première playlist disponible  
**Retour global =>** ferme le dialog

## Apparence du focus

- la playlist focusée doit être surlignée ligne entière ou card entière selon la présentation
- le fond derrière doit paraître inactif
- le bouton **Cancel** doit rester très lisible

## Playlist disponible

### Comportement attendu par action

**UP ↑ =>** playlist précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** playlist suivante si elle existe, sinon bouton **Cancel**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ajoute le film à la playlist sélectionnée  

### Retour

**BACK / ESC =>** ferme le dialog  

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière playlist disponible  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ferme le dialog  

### Retour

**BACK / ESC =>** ferme le dialog  