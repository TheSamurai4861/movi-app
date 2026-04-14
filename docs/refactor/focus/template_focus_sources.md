# FICHE : IPTV Sources

## 1) Contexte
**Page :** IPTV Sources  
**Couverture :** Header, recherche, actions globales, carte de source active, autres sources, suppression

## 2) Audit UI réel avant fiche

### Structure visible confirmée
La page affiche :

- un **header** avec :
  - bouton **Retour**
  - bouton **Recherche**
  - bouton **Ajouter**
- un bouton principal :
  - **Changer de source active**
- un **champ de recherche** seulement si la recherche est ouverte
- une section **Source active**
  - avec une **card d’information**
  - et un **bouton poubelle** en haut à droite de la card
- sous la source active, selon le type :
  - bouton **Rafraîchir**
  - bouton **Modifier** (pas pour Stalker)
  - bouton **Organiser les catégories**
- une section **Autres sources**
  - chaque source est affichée dans une **card d’information**
  - avec **uniquement un bouton poubelle focusable**
- tout en bas :
  - bouton **Ajouter une source**

### Point important
La **card source elle-même n’est pas focusable**.  
Dans cette page, ce qui reçoit le focus côté sources, ce sont surtout :

- le **bouton poubelle** de la source active
- les **boutons poubelle** des autres sources
- les boutons d’action globaux

Donc la page avec “les sources et la poubelle”, c’est bien celle-ci, mais la navigation ne cible pas la card entière comme une destination principale.

---

# Cas 1 — État principal chargé avec source active et autres sources

## Général

**Entrée du focus =>** bouton **Changer de source active**  
**Mémoire du focus au retour =>** oui, sur le dernier bouton focusé si il existe encore  
**Fallback =>** bouton **Changer de source active**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour / recherche / ajouter (header)
- **Focus =>** **fond grisé**
- **pas de contour**

### Boutons primaires
Éléments concernés :
- **Changer de source active**
- **Rafraîchir**
- **Modifier**
- **Organiser les catégories**
- **Ajouter une source**

- **Focus =>** **contour blanc**

### Bouton poubelle
- **Focus =>**
  - fond rouge translucide
  - contour rouge
  - icône poubelle rouge
- c’est un focus très visible et destructif

### Champ de recherche
- **Focus =>** l’input reçoit le focus natif du champ
- fond sombre, prêt à la saisie
- pas de card source focusable autour

### Cards source
- **Non focusables**
- elles restent purement informatives sur cette page

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Changer de source active**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Recherche**

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Recherche"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** champ de recherche si visible, sinon bouton **Changer de source active**  
**LEFT ← =>** bouton **Back**  
**RIGHT → =>** bouton **Ajouter**

### Validation / action

**CLICK / OK / ENTER =>** ouvre / ferme la recherche

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Ajouter" (header)

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Changer de source active**  
**LEFT ← =>** bouton **Recherche**  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la page d’ajout de source

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Changer de source active"

### Comportement attendu par action

**UP ↑ =>** bouton **Recherche** si la recherche n’est pas ouverte, sinon champ de recherche ou bouton Recherche selon l’intention UX retenue  
**DOWN ↓ =>** bouton poubelle de la **source active** si elle existe, sinon premier bouton poubelle des autres sources, sinon bouton **Ajouter une source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la page de sélection de source active

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Champ de recherche

### Comportement attendu par action

**UP ↑ =>** bouton **Recherche**  
**DOWN ↓ =>** premier bouton poubelle des autres sources, sinon bouton **Ajouter une source**  
**LEFT ← =>** bouton **Recherche**  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** active la saisie / garde le focus dans le champ

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton poubelle de la source active

### Comportement attendu par action

**UP ↑ =>** bouton **Changer de source active**  
**DOWN ↓ =>** bouton **Rafraîchir**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la confirmation de suppression de la source active

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Rafraîchir"

### Comportement attendu par action

**UP ↑ =>** bouton poubelle de la source active  
**DOWN ↓ =>** bouton **Modifier** si visible, sinon bouton **Organiser les catégories**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** lance le rafraîchissement de la source active

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Modifier" (si visible)

### Comportement attendu par action

**UP ↑ =>** bouton **Rafraîchir**  
**DOWN ↓ =>** bouton **Organiser les catégories**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre l’édition de la source active

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Organiser les catégories"

### Comportement attendu par action

**UP ↑ =>** bouton **Modifier** si visible, sinon bouton **Rafraîchir**  
**DOWN ↓ =>** premier bouton poubelle des **Autres sources** si il existe, sinon bouton **Ajouter une source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre l’organisation des catégories de la source active

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Premier bouton poubelle d’une autre source

### Comportement attendu par action

**UP ↑ =>** bouton **Organiser les catégories** si une source active existe, sinon champ de recherche si visible, sinon bouton **Changer de source active**  
**DOWN ↓ =>** bouton poubelle de la source suivante si il existe, sinon bouton **Ajouter une source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la confirmation de suppression de cette source

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton poubelle intermédiaire d’une autre source

### Comportement attendu par action

**UP ↑ =>** bouton poubelle précédent  
**DOWN ↓ =>** bouton poubelle suivant si il existe, sinon bouton **Ajouter une source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la confirmation de suppression de cette source

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Dernier bouton poubelle d’une autre source

### Comportement attendu par action

**UP ↑ =>** bouton poubelle précédent  
**DOWN ↓ =>** bouton **Ajouter une source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la confirmation de suppression de cette source

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Ajouter une source" (bas de page)

### Comportement attendu par action

**UP ↑ =>** dernier bouton poubelle des autres sources si il existe, sinon bouton **Organiser les catégories** ou bouton **Changer de source active** selon le contenu affiché  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** ouvre la page d’ajout de source

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 2 — Recherche ouverte

## Général

**Entrée du focus =>** champ de recherche si l’utilisateur vient d’ouvrir la recherche, sinon dernier bouton focusé encore visible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** champ de recherche  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Champ de recherche
- focus natif du champ
- fond sombre, prêt à la saisie
- il devient le point d’entrée principal quand la recherche est ouverte

### Header actions
- **fond grisé**
- **pas de contour**

### Boutons primaires
- **contour blanc**

### Boutons poubelle
- fond rouge + contour rouge

---

## Champ de recherche

### Comportement attendu par action

**UP ↑ =>** bouton **Recherche**  
**DOWN ↓ =>** premier bouton poubelle des autres sources si il existe, sinon bouton **Ajouter une source**  
**LEFT ← =>** bouton **Recherche**  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** active la saisie

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 3 — Aucune autre source, uniquement source active

## Général

**Entrée du focus =>** bouton **Changer de source active**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Changer de source active**  
**Retour global =>** retour à la page précédente

## Apparence du focus

- identique au cas principal
- pas de focus sur des cards de sources
- uniquement sur :
  - header
  - boutons principaux
  - bouton poubelle de la source active
  - bouton d’ajout

## Navigation clé

### Séquence principale verticale attendue

- **Changer de source active**
- **Poubelle source active**
- **Rafraîchir**
- **Modifier** (si visible)
- **Organiser les catégories**
- **Ajouter une source**

---

# Cas 4 — Aucune source active, seulement autres sources

## Général

**Entrée du focus =>** bouton **Changer de source active**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Changer de source active**  
**Retour global =>** retour à la page précédente

## Apparence du focus

- identique au cas principal
- la zone “Source active” devient informative si vide
- la première vraie cible sous le CTA principal devient le **premier bouton poubelle** des autres sources

## Navigation clé

### Séquence principale verticale attendue

- **Changer de source active**
- premier **bouton poubelle** des autres sources
- suivants
- **Ajouter une source**

---

# Cas 5 — Dialog de suppression d’une source

## Général

**Entrée du focus =>** bouton **Confirmer**  
**Mémoire du focus au retour =>** oui, retour sur le bouton poubelle qui a ouvert le dialog  
**Fallback =>** bouton **Annuler**  
**Retour global =>** ferme le dialog

## Apparence du focus

### Bouton "Annuler"
- focus système Cupertino / dialog
- focus clair, standard

### Bouton "Confirmer"
- focus système Cupertino / dialog
- action destructive mise en avant par le texte rouge

### Fond derrière
- inactif tant que le dialog est ouvert

---

## Bouton "Annuler"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Confirmer**

### Validation / action

**CLICK / OK / ENTER =>** annule et ferme le dialog

### Retour

**BACK / ESC =>** ferme le dialog

---

## Bouton "Confirmer"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Annuler**  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** confirme la suppression

### Retour

**BACK / ESC =>** ferme le dialog

---

# Cas 6 — Chargement / refresh en cours

## Général

**Entrée du focus =>** conserve le focus courant si possible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Changer de source active**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton "Rafraîchir"
- peut passer en état loading
- s’il est encore focusable, il garde :
  - **contour blanc**
- si désactivé, il ne doit plus suggérer une action répétable

### Spinner / état de chargement
- purement informatif
- non focusable

## Élément focusé courant

### Comportement attendu par action

**UP ↑ =>** navigation normale entre éléments encore focusables  
**DOWN ↓ =>** navigation normale entre éléments encore focusables  
**LEFT ← =>** navigation normale  
**RIGHT → =>** navigation normale

### Validation / action

**CLICK / OK / ENTER =>** action normale si l’élément est encore actif

### Retour

**BACK / ESC =>** retour à la page précédente