# FICHE : IPTV Source Edit

## 1) Contexte
**Page :** IPTV Source Edit  
**Couverture :** Header, formulaire d’édition, bouton d’action principal, message d’erreur

## 2) Audit UI réel avant fiche

### Structure visible confirmée
La page affiche :

- un **header** avec :
  - bouton **Retour**
  - titre **Modifier**
- un **formulaire vertical** avec 4 champs :
  - **Nom de la source**
  - **URL du serveur**
  - **Username**
  - **Password**
- dans le champ **Password** :
  - une **icône afficher / masquer** le mot de passe
- un bouton principal :
  - **Modifier la source**
- si soumission échouée :
  - un **message d’erreur texte** sous le bouton
- après succès :
  - **pas de dialog**
  - **snackbar** “Source modifiée”
  - puis fermeture de la page

### Point important
Le code confirme :

- entrée de focus sur **Nom de la source**
- navigation verticale stricte entre les champs
- pas de navigation latérale prévue entre les champs, sauf si tu rends l’icône œil navigable
- le bouton principal reçoit le focus après le champ mot de passe
- le bouton retour est un vrai composant focusable
- la snackbar n’est pas focusable

---

# Cas 1 — Formulaire principal, état normal

## Général

**Entrée du focus =>** input **Nom de la source**  
**Mémoire du focus au retour =>** oui, sur le dernier champ focusé si il existe encore  
**Fallback =>** input **Nom de la source**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- c’est un bouton icône custom
- **Focus => fond grisé**
- **pas de contour**
- le code montre déjà un fond blanc translucide quand il est focusé

### Inputs
- **Focus =>** focus natif du champ
- visuellement, les champs ont déjà un fond sombre arrondi
- dans l’état actuel du code, il n’y a **pas de bordure de focus explicite**
- recommandation UI si tu veux uniformiser :
  - halo clair discret ou bordure accent autour du champ focusé

### Bouton œil mot de passe
- bouton icône standard
- **Focus => fond grisé**
- **pas de contour**

### Bouton principal "Modifier la source"
- **Focus => contour blanc**
- c’est l’action principale de la page

### Message d’erreur
- purement informatif
- non focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** input **Nom de la source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Input "Nom de la source"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** input **URL du serveur**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Input "URL du serveur"

### Comportement attendu par action

**UP ↑ =>** input **Nom de la source**  
**DOWN ↓ =>** input **Username**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Input "Username"

### Comportement attendu par action

**UP ↑ =>** input **URL du serveur**  
**DOWN ↓ =>** input **Password**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Input "Password"

### Comportement attendu par action

**UP ↑ =>** input **Username**  
**DOWN ↓ =>** bouton **Modifier la source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Afficher / masquer** si tu veux rendre cette action navigable au clavier / télécommande, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Afficher / masquer" le mot de passe

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Modifier la source**  
**LEFT ← =>** input **Password**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** alterne l’affichage du mot de passe

### Retour

**BACK / ESC =>** retour à l’input **Password**

---

## Bouton "Modifier la source"

### Comportement attendu par action

**UP ↑ =>** input **Password**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** valide le formulaire et lance la modification de la source

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 2 — Formulaire en cours de chargement / soumission

## Général

**Entrée du focus =>** conserve le focus courant si possible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** input **Nom de la source** ou bouton **Modifier la source** selon l’état  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Inputs désactivés
- les champs passent en `enabled: false` pendant `isLoading`
- ils ne doivent plus donner l’impression qu’une saisie est possible

### Bouton "Modifier la source"
- si `loading`
- garde sa place visuelle
- le spinner du bouton est informatif
- si le bouton reste visuellement focusé, il garde :
  - **contour blanc**

### Message d’erreur
- non focusable

### Snackbar
- non concernée ici tant que la soumission n’a pas réussi

---

## Élément focusé courant

### Comportement attendu par action

**UP ↑ =>** navigation normale entre éléments encore focusables  
**DOWN ↓ =>** navigation normale entre éléments encore focusables  
**LEFT ← =>** navigation normale  
**RIGHT → =>** navigation normale  

### Validation / action

**CLICK / OK / ENTER =>** aucune nouvelle action si le bouton est désactivé ; sinon action normale

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 3 — Formulaire avec erreur affichée après soumission

## Général

**Entrée du focus =>** bouton **Modifier la source**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Modifier la source**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton principal
- **Focus => contour blanc**

### Message d’erreur
- texte rouge
- informatif
- non focusable

### Inputs
- redeviennent focusables normalement
- le message d’erreur ne doit pas gêner la lecture du focus

---

## Bouton "Modifier la source"

### Comportement attendu par action

**UP ↑ =>** input **Password**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retente la soumission

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 4 — Succès de modification

## Général

**Entrée du focus =>** non applicable, la page se ferme  
**Mémoire du focus au retour =>** retour sur l’élément qui a ouvert la page d’édition  
**Fallback =>** non applicable  
**Retour global =>** non applicable une fois la page fermée

## Apparence du focus

### Snackbar
- affiche “Source modifiée”
- purement informative
- non focusable

### Page précédente
- doit idéalement restaurer le focus sur la source ou l’action qui a ouvert l’édition

## Après succès

### Comportement attendu

**CLICK / OK / ENTER =>** non applicable  
**BACK / ESC =>** non applicable, la page a déjà été fermée