# FICHE : Search

## 1) Contexte
**Page :** Search  
**Couverture :** Champ de recherche, bouton clear, historique, providers, genres, résultats films / séries / personnes / sagas

---

# Cas 1 — État initial sans query, avec historique visible

## Général

**Entrée du focus =>** input de recherche  
**Mémoire du focus au retour =>** oui, sur la dernière zone utile si encore visible ; sinon input de recherche  
**Fallback =>** input de recherche  
**Retour global =>** retour vers l’icône **Search** du shell latéral

## Apparence du focus

### Input de recherche
- **Focus =>** bordure accent autour du champ
- le champ doit clairement montrer qu’il est prêt à recevoir une saisie

### Bouton clear
- **Focus =>** halo / fond renforcé sur l’icône
- il doit rester visuellement lié à l’input, mais clairement distinct

### Item d’historique
- **Focus =>** ligne entière ou pill entière mise en avant fond grisé
- le focus doit être très lisible sur le premier item de la liste d’historique

### Provider / Genre
- **Focus =>** card entière mise en avant avec contour clair
- les cards focusées doivent être perçues comme destinations directes

---

## Input de recherche

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier item de l’historique si visible, sinon premier provider si visible, sinon premier genre  
**LEFT ← =>** retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** bouton **Clear** si du texte existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active la saisie / garde le focus dans l’input  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Bouton "Clear" (si visible)

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier provider / genre / historique visible sous le champ  
**LEFT ← =>** input de recherche  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** vide la recherche et redonne le focus à l’input  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Item d’historique

### Comportement attendu par action

**UP ↑ =>** item d’historique au-dessus si il existe, sinon input de recherche  
**DOWN ↓ =>** item d’historique suivant si il existe, sinon premier provider si visible, sinon premier genre  
**LEFT ← =>** retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance cette recherche et bascule vers les résultats  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Provider

### Comportement attendu par action

**UP ↑ =>** input de recherche ou item d’historique le plus proche au-dessus  
**DOWN ↓ =>** provider en dessous si il existe, sinon premier genre le plus proche  
**LEFT ← =>** provider suivant sinon retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** provider suivant si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre les résultats liés au provider sélectionné  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Genre

### Comportement attendu par action

**UP ↑ =>** provider le plus proche au-dessus si les providers sont visibles, sinon input / historique  
**DOWN ↓ =>** genre en dessous si il existe, sinon bloqué  
**LEFT ← =>** genre suivant sinon retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** genre suivant si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre les résultats liés au genre sélectionné  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

# Cas 2 — État initial sans query, sans historique

## Général

**Entrée du focus =>** input de recherche  
**Mémoire du focus au retour =>** oui  
**Fallback =>** input de recherche  
**Retour global =>** retour vers l’icône **Search** du shell latéral

## Apparence du focus

- même logique que le cas précédent
- pas de section historique visible
- les premiers blocs focusables sous l’input deviennent les **providers** puis les **genres**, ou directement les **genres** si les providers premium ne sont pas affichés

## Input de recherche

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier provider si visible, sinon premier genre  
**LEFT ← =>** retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** bouton **Clear** si du texte existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active la saisie  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Provider / Genre

### Comportement attendu par action

**UP ↑ =>** élément le plus proche au-dessus, sinon input de recherche  
**DOWN ↓ =>** élément le plus proche en dessous, sinon bloqué  
**LEFT ← =>** genre/provider suivant sinon retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** item suivant si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la vue de résultats correspondante  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

# Cas 3 — Résultats chargés après recherche valide

## Général

**Entrée du focus =>** premier résultat disponible, avec priorité :
1. Films
2. Séries
3. Personnes
4. Sagas

**Mémoire du focus au retour =>** oui, sur le dernier résultat focusé si encore présent  
**Fallback =>** premier résultat disponible  
**Retour global =>** retour vers l’icône **Search** du shell latéral

## Apparence du focus

### Résultat film / série / personne / saga
- **Focus =>** card entière mise en avant
- idéalement : contour lumineux + légère élévation / agrandissement subtil

### Input de recherche
- garde sa bordure accent si refocusé

### Bouton clear
- garde un halo clair sur l’icône lorsqu’il est focusé

- les sections doivent clairement montrer quel premier item reçoit le focus
- le focus doit rester cohérent d’une section à l’autre

---

## Input de recherche

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier résultat disponible  
**LEFT ← =>** retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** bouton **Clear** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active la saisie  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Bouton "Clear"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** premier résultat disponible  
**LEFT ← =>** input de recherche  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** vide la query, recharge l’état initial et redonne le focus à l’input  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Premier résultat d’une section

### Comportement attendu par action

**UP ↑ =>** input de recherche  
**DOWN ↓ =>** résultat situé dessous dans la même section si il existe, sinon premier item de la section suivante  
**LEFT ← =>** retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** résultat suivant dans la même rangée si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche correspondante  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Résultat intermédiaire

### Comportement attendu par action

**UP ↑ =>** résultat le plus proche au-dessus dans la même section, sinon input si on est tout en haut  
**DOWN ↓ =>** résultat le plus proche en dessous dans la même section, sinon premier item de la section suivante  
**LEFT ← =>** résultat précédent si il existe, sinon retour vers l’icône **Search** du shell latéral si on est premier item de rangée  
**RIGHT → =>** résultat suivant si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche correspondante  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

## Dernier résultat d’une section

### Comportement attendu par action

**UP ↑ =>** résultat le plus proche au-dessus  
**DOWN ↓ =>** premier item de la section suivante si elle existe, sinon bloqué  
**LEFT ← =>** résultat précédent  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la fiche correspondante  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

# Cas 4 — Chargement

## Général

**Entrée du focus =>** input de recherche  
**Mémoire du focus au retour =>** non applicable pour le contenu chargé  
**Fallback =>** input de recherche  
**Retour global =>** retour vers l’icône **Search** du shell latéral

## Apparence du focus

- le spinner et la zone de chargement doivent rester purement informatifs
- seul l’input de recherche peut rester naturellement focusable
- aucun autre élément ne doit suggérer une action disponible pendant le chargement

## Input de recherche

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** bouton **Clear** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** permet de modifier la recherche  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  

---

# Cas 5 — Erreur

## Général

**Entrée du focus =>** input de recherche  
**Mémoire du focus au retour =>** non  
**Fallback =>** input de recherche  
**Retour global =>** retour vers l’icône **Search** du shell latéral

## Apparence du focus

- le message d’erreur reste informatif
- aucun bouton Retry visible n’étant affiché ici, aucun focus ne doit suggérer une action dans le corps de page
- seul le champ de recherche reste une cible logique pour corriger la requête

## Input de recherche

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** retour vers l’icône **Search** du shell latéral  
**RIGHT → =>** bouton **Clear** si visible, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** permet de corriger la recherche  

### Retour

**BACK / ESC =>** retour vers l’icône **Search** du shell latéral  