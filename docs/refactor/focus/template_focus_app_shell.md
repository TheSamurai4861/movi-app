# FICHE : App Shell

## 1) Contexte
**Page :** App Shell  
**Couverture :** Ensemble du shell de navigation

---

## 2) Comportement général

**Entrée du focus =>** le focus arrive sur l’icône de menu correspondant à la section active, selon la page depuis laquelle l’utilisateur revient.

- Accueil => icône **Home**
- Recherche => icône **Search**
- Bibliothèque => icône **Library**
- Paramètres => icône **Settings**

**Mémoire du focus =>** oui, le shell conserve l’association entre chaque icône de menu et le dernier élément focusé dans la page liée.

**Fallback =>** si aucun dernier focus mémorisé n’existe pour la page associée, le focus va sur le composant défini comme **focus d’entrée** de cette page.

---

## 3) Composants

### Icônes de menu
**Éléments concernés :** Home, Search, Library, Settings

#### Comportement attendu par action

**UP ↑ =>** déplace le focus vers l’icône située au-dessus, si elle existe. Sinon, le focus reste sur place.  

**DOWN ↓ =>** déplace le focus vers l’icône située en dessous, si elle existe. Sinon, le focus reste sur place.  

**LEFT ← =>** focus bloqué, aucun déplacement.  

**RIGHT → =>** entre dans la page associée à l’icône :
- en restaurant le **dernier élément focusé** de cette page si disponible
- sinon en ciblant son **focus d’entrée**

#### Validation / action

**CLICK / OK / ENTER =>** même comportement que `RIGHT` :
- retour au dernier élément focusé de la page associée si disponible
- sinon focus sur le composant défini comme focus d’entrée

#### Retour

**BACK / ESC =>**
- au premier appui : affichage d’une **snackbar** indiquant qu’un second appui quittera l’application
- au second appui consécutif : **fermeture de l’application**

---

## 4) Apparence du focus

- l’icône focusée doit être **visuellement isolée** des autres
- le focus doit être visible sous forme de **contour net**, **halo**, ou **renforcement du fond**
- l’état **focusé** doit rester distinct de l’état **actif/sélectionné**
- si l’icône est à la fois **active** et **focusée**, la priorité visuelle doit rendre évident qu’elle est la cible courante de navigation
- le focus ne doit jamais être ambigu entre deux icônes voisines