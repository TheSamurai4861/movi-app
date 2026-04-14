# FICHE : IPTV Source Organize

## 1) Contexte
**Page :** IPTV Source Organize  
**Couverture :** Header, bouton retour, liste réordonnable des catégories, bouton reset, drag handles, sauvegarde / sortie

## 2) Audit UI réel avant fiche

### Structure visible confirmée
La page affiche :

- un **header** avec :
  - bouton **Retour**
  - titre de sous-page
  - bouton **Reset** si des changements existent
- un corps avec une **liste verticale de catégories**
- chaque ligne de catégorie contient généralement :
  - le **nom de la catégorie**
  - parfois des infos secondaires
  - une **poignée de drag / réorganisation**
- selon l’état :
  - soit la liste
  - soit un **message vide**
  - soit un **chargement**
- la sortie de page déclenche potentiellement une sauvegarde / confirmation implicite selon l’état des changements

### Point important
Sur ce type de page, les vrais éléments focusables attendus sont :

- le **bouton Retour**
- le **bouton Reset** si visible
- chaque **ligne de catégorie**
- éventuellement la **poignée de drag** si elle est rendue focusable séparément  
  mais, pour une navigation TV / clavier propre, il est préférable que **la ligne entière** soit la cible principale, pas seulement la poignée

---

# Cas 1 — Liste chargée, sans mode déplacement actif

## Général

**Entrée du focus =>** première catégorie de la liste  
**Mémoire du focus au retour =>** oui, sur la dernière catégorie focusée si elle existe encore  
**Fallback =>** première catégorie, sinon bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus => fond grisé**
- **pas de contour**

### Bouton "Reset"
- **Focus => contour blanc**
- c’est une action primaire / importante quand elle est visible

### Ligne de catégorie
- **Focus =>** ligne entière mise en avant
- idéalement :
  - fond légèrement renforcé
  - contour clair discret
  - drag handle toujours visible
- une seule catégorie doit paraître active à la fois

### Drag handle
- si non focusable séparément :
  - reste purement décoratif / informatif
- si focusable séparément :
  - **Focus => fond grisé**
  - **pas de contour**
- mais recommandé : **éviter** un focus séparé sur la poignée pour garder une navigation simple

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première catégorie de la liste, sinon bouton **Reset** si aucun item n’est présent  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Reset** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente ; si des changements non sauvegardés existent, applique la logique de sortie prévue

### Retour

**BACK / ESC =>** retour à la page précédente ; si des changements non sauvegardés existent, applique la logique de sortie prévue

---

## Bouton "Reset" (si visible)

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première catégorie  
**LEFT ← =>** bouton **Back**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** réinitialise l’ordre des catégories

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Première catégorie

### Comportement attendu par action

**UP ↑ =>** bouton **Reset** si visible, sinon bouton **Back**  
**DOWN ↓ =>** catégorie suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** drag handle si tu choisis de le rendre focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** entre en mode déplacement / sélection de réorganisation pour cette catégorie

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Catégorie intermédiaire

### Comportement attendu par action

**UP ↑ =>** catégorie précédente  
**DOWN ↓ =>** catégorie suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** drag handle si focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** entre en mode déplacement / sélection de réorganisation pour cette catégorie

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Dernière catégorie

### Comportement attendu par action

**UP ↑ =>** catégorie précédente  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** drag handle si focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** entre en mode déplacement / sélection de réorganisation pour cette catégorie

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 2 — Mode déplacement actif d’une catégorie

## Général

**Entrée du focus =>** catégorie actuellement déplacée  
**Mémoire du focus au retour =>** oui, sur la catégorie repositionnée  
**Fallback =>** catégorie en cours de déplacement  
**Retour global =>** annule ou quitte le mode déplacement selon la règle retenue

## Apparence du focus

### Catégorie déplacée
- **Focus =>** état très visible
- idéalement :
  - contour accent fort
  - fond renforcé
  - indicateur “mode déplacement” explicite
- il doit être évident qu’on n’est plus dans une navigation simple, mais dans une logique de réordonnancement

### Autres catégories
- restent visibles mais non actives
- elles servent de repères de position

### Boutons de header
- ne doivent pas reprendre le focus pendant le déplacement

---

## Catégorie en déplacement

### Comportement attendu par action

**UP ↑ =>** déplace la catégorie d’un cran vers le haut si possible, sinon bloqué  
**DOWN ↓ =>** déplace la catégorie d’un cran vers le bas si possible, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** confirme la nouvelle position et quitte le mode déplacement

### Retour

**BACK / ESC =>** annule le déplacement en cours ou quitte le mode déplacement sans valider, selon la règle produit retenue

---

# Cas 3 — Liste vide

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus => fond grisé**
- **pas de contour**

### Bouton "Reset"
- si visible malgré l’état vide
- **Focus => contour blanc**

### Message vide
- purement informatif
- non focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Reset** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 4 — Chargement

## Général

**Entrée du focus =>** bouton **Back**  
**Mémoire du focus au retour =>** non applicable  
**Fallback =>** bouton **Back**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus => fond grisé**
- **pas de contour**

### Zone de chargement
- spinner / skeleton purement informatif
- aucun autre élément ne doit sembler focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Reset** si visible, sinon bloqué  

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
- **Focus => fond grisé**
- **pas de contour**

### Bouton primaire de récupération
- **Focus => contour blanc**

### Message d’erreur
- purement informatif
- non focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton de récupération si visible, sinon bloqué  
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

**CLICK / OK / ENTER =>** relance le chargement ou restaure l’état

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 6 — Changements en attente avant sortie

## Général

**Entrée du focus =>** dernier élément focusé  
**Mémoire du focus au retour =>** oui  
**Fallback =>** dernière catégorie focusée, sinon bouton **Back**  
**Retour global =>** si sortie demandée, déclenche la logique de confirmation / sauvegarde prévue

## Apparence du focus

### Bouton "Back"
- **Focus => fond grisé**
- **pas de contour**

### Bouton "Reset"
- **Focus => contour blanc**

### Catégorie
- focus normal de ligne entière

### Dialog de confirmation éventuel
- si un dialog apparaît, il prend toute la priorité visuelle
- fond derrière inactif

---

## Si dialog de confirmation s’ouvre

### Bouton principal de confirmation

**UP ↑ =>** bloqué  
**DOWN ↓ =>** autre bouton éventuel si présent  
**LEFT ← =>** autre bouton éventuel si présent  
**RIGHT → =>** bloqué  

**CLICK / OK / ENTER =>** confirme la sortie / sauvegarde / abandon selon le libellé

**BACK / ESC =>** ferme le dialog ou revient à l’écran selon la règle choisie

---

## Bouton secondaire / Annuler (si présent)

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** autre bouton si présent  
**RIGHT → =>** autre bouton si présent  

### Validation / action

**CLICK / OK / ENTER =>** annule la sortie et revient à la page

### Retour

**BACK / ESC =>** ferme le dialog