# FICHE : About

## 1) Contexte
**Page :** About  
**Couverture :** Header de sous-page, bouton retour, sections d’information, liens / actions éventuels, blocs diagnostic

---

# Cas 1 — Desktop / TV, état principal chargé

## Général

**Entrée du focus =>** premier élément interactif visible de la page  
**Priorité d’entrée =>**
1. premier lien / bouton d’action visible
2. sinon bouton **Back**
3. sinon aucun focus utile si la page est purement informative

**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si il existe encore  
**Fallback =>** premier élément interactif visible, sinon bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Bouton primaire
- **Focus =>** **contour blanc**

### Bouton icône
- **Focus =>** **fond grisé**
- **pas de contour**

### Lien / item d’information interactif
- **Focus =>** ligne entière ou bloc entier mis en avant
- idéalement :
  - fond légèrement renforcé
  - contour clair discret
  - texte et trailing bien lisibles

### Bloc purement informatif
- non focusable
- aucun halo, contour ou état actif ne doit suggérer une action

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier élément interactif visible sous le header, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Premier item / lien interactif

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** item interactif suivant si il existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** contrôle trailing si il existe et qu’il est focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le lien, exécute l’action ou copie l’information selon le composant réel  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Item / lien interactif intermédiaire

### Comportement attendu par action

**UP ↑ =>** item interactif précédent  
**DOWN ↓ =>** item interactif suivant si il existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** contrôle trailing si il existe et qu’il est focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le lien, exécute l’action ou copie l’information selon le composant réel  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Dernier item / lien interactif

### Comportement attendu par action

**UP ↑ =>** item interactif précédent  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** contrôle trailing si il existe et qu’il est focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le lien, exécute l’action ou copie l’information selon le composant réel  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Contrôle trailing focusable (si présent)

### Comportement attendu par action

**UP ↑ =>** item interactif précédent  
**DOWN ↓ =>** item interactif suivant  
**LEFT ← =>** item parent  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** exécute l’action du contrôle  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 2 — Mobile / tablette, état principal chargé

## Général

**Entrée du focus =>** premier élément interactif visible  
**Priorité d’entrée =>**
1. premier lien / bouton d’action visible
2. sinon bouton **Back**
3. sinon aucun focus utile si la page est entièrement informative

**Mémoire du focus au retour =>** oui  
**Fallback =>** premier élément interactif visible, sinon bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

- même logique que desktop / TV
- le **bouton retour** garde :
  - **fond grisé**
  - **pas de contour**
- les items interactifs sont focusés **ligne entière**
- les boutons primaires gardent :
  - **contour blanc**
- les boutons icône gardent :
  - **fond grisé**
  - **pas de contour**

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier élément interactif visible sous le header, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Item / lien interactif

### Comportement attendu par action

**UP ↑ =>** item précédent, ou bouton **Back** pour le premier  
**DOWN ↓ =>** item suivant si il existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** trailing focusable si présent, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le lien, exécute l’action ou copie l’information selon le composant réel  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

## Contrôle trailing

### Comportement attendu par action

**UP ↑ =>** item précédent  
**DOWN ↓ =>** item suivant  
**LEFT ← =>** item parent  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** exécute l’action du contrôle  

### Retour

**BACK / ESC =>** retour à la page précédente  

---

# Cas 3 — Page purement informative, sans élément interactif dans le corps

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non nécessaire  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Corps de page
- entièrement informatif
- aucun bloc ne doit sembler focusable
- aucune ligne ne doit recevoir de halo, contour ou surbrillance de focus

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

# Cas 4 — Chargement / état transitoire

## Général

**Entrée du focus =>** bouton **Back** si la page est déjà montée, sinon aucun focus utile  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus =>** **fond grisé**
- **pas de contour**

### Zone de chargement
- le spinner / squelette reste purement informatif
- aucun autre élément ne doit sembler focusable

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

# Cas 5 — Erreur simple

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

**CLICK / OK / ENTER =>** relance l’action de récupération  

### Retour

**BACK / ESC =>** retour à la page précédente  