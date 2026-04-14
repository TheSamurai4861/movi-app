# FICHE : Splash Bootstrap

## 1) Contexte
**Page :** Splash Bootstrap  
**Couverture :** État de démarrage + état erreur

---

## 2) Comportement général

**Entrée du focus =>** aucun focus visible en état normal ; uniquement sur le bouton **Retry** si la page passe en erreur  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Retry** si l’état erreur est affiché  
**Retour global =>** bloqué

## 3) Apparence du focus

- en état normal, aucun élément ne doit sembler focusable
- le logo, le spinner et le texte de progression doivent rester purement informatifs
- en état erreur, le bouton **Retry** doit recevoir un focus très lisible :
  - contour clair
  - halo ou mise en avant du fond
  - séparation nette par rapport au message d’erreur
- l’écran doit clairement passer d’un état **passif** à un état **actionnable** uniquement quand l’erreur est affichée

---

## 4) Composants

### Bouton "Retry"

#### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

#### Validation / action

**CLICK / OK / ENTER =>** relance le bootstrap / le chargement  

#### Retour

**BACK / ESC =>** bloqué  