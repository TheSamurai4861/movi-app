# FICHE : Movi Premium

## 1) Contexte
**Page :** Movi Premium  
**Couverture :** Header, intro, bénéfices, offres, plan actif, restauration d’achats

---

# Cas 1 — Offres affichées, page chargée

## Général

**Entrée du focus =>** premier bouton **Acheter / S’abonner** disponible  
**Mémoire du focus au retour =>** oui, sur le dernier bouton d’offre ou bouton de restauration focusé si encore présent  
**Fallback =>**
1. premier bouton d’offre disponible
2. sinon bouton **Restaurer**
3. sinon bouton **Back**

**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Bouton primaire d’offre
- **Focus =>** **contour blanc**
- le bouton doit être perçu comme l’action principale de la page

### Bouton secondaire / restauration
- **Focus =>** **contour blanc**
- il reste secondaire par sa hiérarchie visuelle, mais son focus doit être très lisible

### Cards d’intro / bénéfices / plan
- non focusables
- aucun halo, contour ou état actif ne doit suggérer une interaction sur ces blocs

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier bouton d’offre disponible, sinon bouton **Restaurer** si visible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Premier bouton d’offre

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bouton d’offre suivant si il existe, sinon bouton **Restaurer** si visible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** lance l’achat / l’abonnement de l’offre sélectionnée  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton d’offre intermédiaire

### Comportement attendu par action

**UP ↑ =>** bouton d’offre précédent  
**DOWN ↓ =>** bouton d’offre suivant si il existe, sinon bouton **Restaurer** si visible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** lance l’achat / l’abonnement de l’offre sélectionnée  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Dernier bouton d’offre

### Comportement attendu par action

**UP ↑ =>** bouton d’offre précédent  
**DOWN ↓ =>** bouton **Restaurer** si visible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** lance l’achat / l’abonnement de l’offre sélectionnée  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Restaurer"

### Comportement attendu par action

**UP ↑ =>** dernier bouton d’offre si il existe, sinon bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** lance la restauration des achats  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 2 — Abonnement actif affiché

## Général

**Entrée du focus =>** bouton **Restaurer** si visible et activé, sinon bouton **Back**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Restaurer** si visible, sinon bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Bouton "Restaurer"
- **Focus =>** **contour blanc**

### Card "Plan actuel"
- informative
- non focusable

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Restaurer** si visible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Restaurer"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** lance la restauration des achats  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 3 — Chargement initial des offres

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Zone de chargement
- le spinner reste purement informatif
- aucune autre zone ne doit sembler focusable pendant ce chargement

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

# Cas 4 — Aucune offre disponible, preview statique affichée

## Général

**Entrée du focus =>** bouton **Back** ou bouton **Restaurer** si visible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Restaurer** si visible, sinon bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Preview desktop des offres
- les boutons "Choisir" affichés dans la preview sont désactivés / non interactifs
- ils ne doivent pas sembler focusables

### Bouton "Restaurer"
- **Focus =>** **contour blanc**

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Restaurer** si visible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Restaurer"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** lance la restauration des achats  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 5 — Facturation indisponible / achats désactivés

## Général

**Entrée du focus =>** bouton **Restaurer** si visible et activé, sinon bouton **Back**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Restaurer** si visible, sinon bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Boutons d’offre désactivés
- non focusables
- ils doivent visuellement paraître indisponibles
- aucun contour de focus ne doit apparaître dessus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Bouton "Restaurer"
- **Focus =>** **contour blanc**

### Message d’indisponibilité
- purement informatif
- non focusable

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Restaurer** si visible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Bouton "Restaurer"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** tente la restauration des achats  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 6 — Action en cours (achat ou restauration busy)

## Général

**Entrée du focus =>** élément déjà focusé avant le passage en état busy, si il reste visible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Boutons désactivés pendant l’action
- ne doivent plus être focusables si l’état busy les désactive réellement
- sinon leur focus doit rester stable mais l’état busy doit être clairement visible

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Spinner / indicateur réseau
- purement informatif
- non focusable

## Élément focusé courant

### Comportement attendu par action

**UP ↑ =>** navigation normale entre les éléments encore focusables  
**DOWN ↓ =>** navigation normale entre les éléments encore focusables  
**LEFT ← =>** navigation normale  
**RIGHT → =>** navigation normale  

### Validation / action

**CLICK / OK / ENTER =>** aucune nouvelle action sur les boutons désactivés ; action normale sur un élément encore actif  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 7 — Refresh pull-to-refresh / état transitoire après retour

## Général

**Entrée du focus =>** conserve le focus courant si possible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** premier bouton d’offre, sinon bouton **Restaurer**, sinon bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Focus courant
- il doit rester stable pendant le refresh
- le refresh indicator ne doit pas prendre le focus

### Bouton primaire
- **Focus =>** **contour blanc**

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

## Élément focusé courant

### Comportement attendu par action

**UP ↑ =>** navigation normale selon la zone focusée  
**DOWN ↓ =>** navigation normale selon la zone focusée  
**LEFT ← =>** navigation normale selon la zone focusée  
**RIGHT → =>** navigation normale selon la zone focusée  

### Validation / action

**CLICK / OK / ENTER =>** action normale de l’élément focusé si il est encore actif  

### Retour

**BACK / ESC =>** retour à la page précédente  