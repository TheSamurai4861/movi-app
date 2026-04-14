# FICHE : Settings Subtitles

## 1) Contexte
**Page :** Settings Subtitles  
**Couverture :** Header de sous-page, bouton retour, items de réglages des sous-titres, contrôles trailing, sélecteurs / dialogs associés

---

# Cas 1 — Desktop / TV, état principal chargé

## Général

**Entrée du focus =>** premier item de réglage  
**Mémoire du focus au retour =>** oui, sur le dernier item ou contrôle focusé si il existe encore  
**Fallback =>** premier item de réglage  
**Retour global =>** retour à la page précédente  
**Sortie latérale gauche =>** non, priorité au retour vers la page Settings

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Item de réglage
- **Focus =>** ligne entière mise en avant
- idéalement :
  - fond légèrement renforcé
  - contour clair discret
  - libellé, valeur et chevron restent bien lisibles

### Contrôle trailing
- **Focus =>** si le contrôle est focusable individuellement :
  - **bouton primaire => contour blanc**
  - **bouton icône => fond grisé, pas de contour**
  - **contrôle standard / valeur => fond renforcé ou contour discret**

### Zone de preview éventuelle
- purement informative
- non focusable si aucune interaction dédiée n’est prévue

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier item de réglage  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Premier item de réglage

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** item suivant  
**LEFT ← =>** bloqué  
**RIGHT → =>** contrôle trailing si il existe et qu’il est focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le sélecteur ou active le réglage correspondant  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Item intermédiaire de réglage

### Comportement attendu par action

**UP ↑ =>** item précédent  
**DOWN ↓ =>** item suivant si il existe, sinon dernier item / contrôle suivant  
**LEFT ← =>** bloqué  
**RIGHT → =>** contrôle trailing si il existe et qu’il est focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le sélecteur ou active le réglage correspondant  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Dernier item de réglage

### Comportement attendu par action

**UP ↑ =>** item précédent  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** contrôle trailing si il existe et qu’il est focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le sélecteur ou active le réglage correspondant  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Contrôle trailing focusable

### Comportement attendu par action

**UP ↑ =>** item précédent  
**DOWN ↓ =>** item suivant  
**LEFT ← =>** item parent  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** exécute l’action du contrôle ou ouvre le sélecteur associé  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 3 — Sélecteur / dialog de valeur (taille, style, couleur, fond, opacité, etc.)

## Général

**Entrée du focus =>** option actuellement sélectionnée si possible, sinon première option  
**Mémoire du focus au retour =>** oui, retour sur l’item de réglage qui a ouvert le sélecteur  
**Fallback =>** première option  
**Retour global =>** ferme le sélecteur / dialog

## Apparence du focus

### Option
- **Focus =>** ligne entière mise en avant
- l’option sélectionnée et l’option focusée doivent rester distinguables

### Bouton primaire éventuel
- **Focus =>** **contour blanc**

### Bouton secondaire / Cancel
- **Focus =>** fond renforcé ou contour discret

### Bouton icône éventuel
- **Focus =>** **fond grisé**
- **pas de contour**

---

## Option

### Comportement attendu par action

**UP ↑ =>** option précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** option suivante si elle existe, sinon bouton **Cancel** si présent  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** applique l’option sélectionnée  

### Retour

**BACK / ESC =>** ferme le sélecteur / dialog  

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière option  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ferme le sélecteur / dialog  

### Retour

**BACK / ESC =>** ferme le sélecteur / dialog  

---

# Cas 4 — Contrôle incrémental / stepper (si présent pour taille, décalage, opacité, etc.)

## Général

**Entrée du focus =>** valeur actuelle ou bouton principal du stepper  
**Mémoire du focus au retour =>** oui, retour sur le réglage qui a ouvert ce contrôle  
**Fallback =>** contrôle central / valeur  
**Retour global =>** ferme le contrôle si il est modal, sinon retour à la page précédente

## Apparence du focus

### Bouton moins / plus
- si affichés comme boutons icône :
  - **Focus => fond grisé**
  - **pas de contour**

### Bouton primaire de validation éventuel
- **Focus => contour blanc**

### Valeur centrale
- si focusable :
  - fond légèrement renforcé
  - contour discret

---

## Bouton "Moins"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton de validation si il existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** valeur centrale ou bouton **Plus** selon le layout réel  

### Validation / action

**CLICK / OK / ENTER =>** diminue la valeur  

### Retour

**BACK / ESC =>** ferme le contrôle / revient en arrière  

---

## Valeur centrale (si focusable)

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton de validation si il existe, sinon bloqué  
**LEFT ← =>** bouton **Moins**  
**RIGHT → =>** bouton **Plus**  

### Validation / action

**CLICK / OK / ENTER =>** aucune action ou bascule vers édition selon le composant réel  

### Retour

**BACK / ESC =>** ferme le contrôle / revient en arrière  

---

## Bouton "Plus"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton de validation si il existe, sinon bloqué  
**LEFT ← =>** valeur centrale ou bouton **Moins**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** augmente la valeur  

### Retour

**BACK / ESC =>** ferme le contrôle / revient en arrière  

---

# Cas 5 — Chargement / état transitoire

## Général

**Entrée du focus =>** bouton **Back** si la sous-page est déjà montée, sinon aucun focus utile  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Zone de chargement
- le spinner ou la zone transitoire reste purement informatif
- aucun élément du contenu ne doit sembler focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué tant que le contenu n’est pas prêt  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 6 — Erreur simple

## Général

**Entrée du focus =>** bouton **Back**, ou bouton primaire de récupération si un CTA existe  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Bouton primaire de récupération
- **Focus =>** **contour blanc**

### Message d’erreur
- purement informatif
- non focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton primaire de récupération si il existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton primaire de récupération (si visible)

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement ou réapplique le réglage  

### Retour

**BACK / ESC =>** retour à la page précédente  