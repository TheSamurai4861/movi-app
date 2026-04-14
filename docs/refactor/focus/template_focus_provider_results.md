# FICHE : Provider Results

## 1) Contexte
**Page :** Provider Results  
**Couverture :** Header, bouton retour, sections Films / Séries, cards média, cards "See all", états d’erreur par section, état vide, chargement

---

# Cas 1 — Résultats chargés avec sections Films et/ou Séries

## Général

**Entrée du focus =>** première card **Film** si disponible, sinon première card **Série**  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si encore présent  
**Fallback =>** première card disponible  
**Retour global =>** retour à la page précédente  
**Sortie latérale gauche =>** shell latéral si présent

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Card média
- **Focus =>** card entière mise en avant
- idéalement :
  - contour accent visible
  - légère élévation
  - agrandissement subtil

### Card "See all"
- **Focus =>** card entière mise en avant, comme une vraie destination interactive
- elle doit rester distincte d’une card média standard

### Bouton primaire
- **Focus =>** **contour blanc**

### Bouton icône
- **Focus =>** **fond grisé**
- **pas de contour**

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première card disponible  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Première card Films

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** première card **Séries** si la section existe dessous, sinon bloqué  
**LEFT ← =>** shell latéral si présent, sinon bloqué  
**RIGHT → =>** card Film suivante si elle existe, sinon card **See all Films** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du film  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Card Film intermédiaire

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** card Série la plus proche si la section existe dessous, sinon bloqué  
**LEFT ← =>** card Film précédente si elle existe, sinon shell latéral si présent  
**RIGHT → =>** card Film suivante si elle existe, sinon card **See all Films** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du film  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Card "See all Films"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** card Série la plus proche si la section existe dessous, sinon bloqué  
**LEFT ← =>** dernière card Film  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre **Provider All Results** pour les films  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Première card Séries

### Comportement attendu par action

**UP ↑ =>** card Film la plus proche au-dessus si la section Films existe, sinon bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** shell latéral si présent, sinon bloqué  
**RIGHT → =>** card Série suivante si elle existe, sinon card **See all Séries** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche de la série  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Card Série intermédiaire

### Comportement attendu par action

**UP ↑ =>** card Film la plus proche au-dessus si la section Films existe, sinon bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** card Série précédente si elle existe, sinon shell latéral si présent  
**RIGHT → =>** card Série suivante si elle existe, sinon card **See all Séries** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche de la série  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Card "See all Séries"

### Comportement attendu par action

**UP ↑ =>** card Film la plus proche au-dessus si la section Films existe, sinon bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** dernière card Série  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre **Provider All Results** pour les séries  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 2 — Seulement Films chargés

## Général

**Entrée du focus =>** première card Film  
**Mémoire du focus au retour =>** oui  
**Fallback =>** première card Film  
**Retour global =>** retour à la page précédente

## Apparence du focus

- même logique que le cas principal
- cards Film et éventuel **See all Films** focusées par la card entière
- bouton retour : **fond grisé**, **pas de contour**

## Card Film

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** card précédente sinon shell latéral si présent  
**RIGHT → =>** card suivante sinon card **See all Films** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche du film  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 3 — Seulement Séries chargées

## Général

**Entrée du focus =>** première card Série  
**Mémoire du focus au retour =>** oui  
**Fallback =>** première card Série  
**Retour global =>** retour à la page précédente

## Apparence du focus

- même logique que le cas principal
- cards Série et éventuel **See all Séries** focusées par la card entière
- bouton retour : **fond grisé**, **pas de contour**

## Card Série

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** card précédente sinon shell latéral si présent  
**RIGHT → =>** card suivante sinon card **See all Séries** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche de la série  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 4 — Erreur section Films avec bouton Retry

## Général

**Entrée du focus =>** bouton **Retry Films** si la section Films est la première zone interactive disponible ; sinon première zone disponible  
**Mémoire du focus au retour =>** oui, si la zone existe encore  
**Fallback =>** bouton **Retry Films**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton primaire Retry
- **Focus =>** **contour blanc**

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

- le message d’erreur reste informatif
- le bouton Retry doit être clairement l’action principale de récupération

## Bouton "Retry Films"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** première zone interactive dessous, par exemple première card Séries si présente  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement de la section Films  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 5 — Erreur section Séries avec bouton Retry

## Général

**Entrée du focus =>** première card Films si disponible, sinon bouton **Retry Séries**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Retry Séries**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton primaire Retry
- **Focus =>** **contour blanc**

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

## Bouton "Retry Séries"

### Comportement attendu par action

**UP ↑ =>** dernière zone interactive au-dessus, généralement dernière card Films ou **See all Films**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement de la section Séries  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 6 — État vide global

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

- le message vide doit rester purement informatif
- aucun autre élément du corps de page ne doit sembler interactif

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** shell latéral si présent, sinon bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 7 — Chargement global

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

- le spinner reste purement informatif
- aucune autre zone ne doit sembler focusable pendant ce chargement

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** shell latéral si présent, sinon bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  