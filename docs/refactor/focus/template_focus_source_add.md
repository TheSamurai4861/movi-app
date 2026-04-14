# FICHE : IPTV Source Add

## 1) Contexte
**Page :** IPTV Source Add  
**Couverture :** Header, formulaire d’ajout, bouton d’action principal, message d’erreur, dialog de confirmation post-ajout

## 2) Audit UI réel avant fiche

### Structure visible confirmée
La page affiche :

- un **header** avec :
  - bouton **Retour**
  - titre **Ajouter**
- un **formulaire vertical** avec 4 champs :
  - **Nom de la source**
  - **URL du serveur**
  - **Username**
  - **Password**
- dans le champ **Password** :
  - une **icône afficher / masquer** le mot de passe
- un bouton principal :
  - **Ajouter la source**
- si soumission échouée :
  - un **message d’erreur texte** sous le bouton
- après ajout réussi :
  - un **dialog** :
    - **Plus tard**
    - **Utiliser**

### Point important
Le code de navigation directionnelle explicite confirme :

- entrée de focus sur **Nom de la source**
- navigation verticale stricte entre les champs
- pas de navigation latérale prévue entre les champs
- le bouton œil du mot de passe est **cliquable**, mais il n’a pas de routage directional explicite prévu dans ce fichier
- le bouton principal reçoit le focus après le champ mot de passe
- le dialog post-ajout ouvre le focus sur **Utiliser**

---

# Cas 1 — Formulaire principal, état normal

## Général

**Entrée du focus =>** input **Nom de la source**  
**Mémoire du focus au retour =>** oui, sur le dernier champ focusé si il existe encore  
**Fallback =>** input **Nom de la source**  
**Retour global =>** retour à la page précédente ou vers `IPTV Sources` si la page n’a pas d’historique de navigation

## Apparence du focus

### Bouton retour
- **Focus =>** état du composant header back
- visuellement, à traiter comme un **bouton icône**
- recommandation UI :
  - **fond grisé**
  - **pas de contour**

### Inputs
- **Focus =>** champ actif natif
- dans l’UI actuelle, le champ a déjà un fond sombre arrondi
- recommandation UI focus :
  - halo clair ou bordure accent discrète autour du champ focusé
  - sans casser le style pill / arrondi existant

### Bouton œil mot de passe
- **Focus =>** bouton icône
- recommandation UI :
  - **fond grisé**
  - **pas de contour**

### Bouton principal "Ajouter la source"
- **Focus =>** **contour blanc**
- bouton principal de la page, le focus doit être très lisible

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

**CLICK / OK / ENTER =>** retour à la page précédente, ou navigation fallback vers `IPTV Sources`

### Retour

**BACK / ESC =>** retour à la page précédente, ou navigation fallback vers `IPTV Sources`

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

**BACK / ESC =>** retour à la page précédente / fallback

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

**BACK / ESC =>** retour à la page précédente / fallback

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

**BACK / ESC =>** retour à la page précédente / fallback

---

## Input "Password"

### Comportement attendu par action

**UP ↑ =>** input **Username**  
**DOWN ↓ =>** bouton **Ajouter la source**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Afficher / masquer** le mot de passe si tu veux rendre cette action navigable au clavier / télécommande, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ

### Retour

**BACK / ESC =>** retour à la page précédente / fallback

---

## Bouton "Afficher / masquer" le mot de passe

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Ajouter la source**  
**LEFT ← =>** input **Password**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** alterne l’affichage du mot de passe

### Retour

**BACK / ESC =>** retour à l’input **Password**

---

## Bouton "Ajouter la source"

### Comportement attendu par action

**UP ↑ =>** input **Password**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** valide le formulaire et lance l’ajout de la source

### Retour

**BACK / ESC =>** retour à la page précédente / fallback

---

# Cas 2 — Formulaire en cours de chargement / soumission

## Général

**Entrée du focus =>** conserve le focus courant si possible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** input **Nom de la source** ou bouton **Ajouter la source** selon l’état  
**Retour global =>** retour à la page précédente / fallback

## Apparence du focus

### Inputs désactivés
- les champs deviennent non éditables pendant `isLoading`
- ils ne doivent pas donner l’impression qu’une nouvelle saisie est possible

### Bouton "Ajouter la source"
- si `loading`
- conserve sa place visuelle
- le spinner du bouton est informatif
- si le bouton reste focusable visuellement, son focus doit rester lisible :
  - **contour blanc**

### Message d’erreur
- non focusable

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

**BACK / ESC =>** retour à la page précédente / fallback

---

# Cas 3 — Formulaire avec erreur affichée après soumission

## Général

**Entrée du focus =>** bouton **Ajouter la source**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Ajouter la source**  
**Retour global =>** retour à la page précédente / fallback

## Apparence du focus

### Bouton principal
- **Focus =>** **contour blanc**

### Message d’erreur
- texte rouge
- informatif
- non focusable

### Inputs
- focusables normalement
- le message d’erreur ne doit pas interférer avec la lecture du focus

---

## Bouton "Ajouter la source"

### Comportement attendu par action

**UP ↑ =>** input **Password**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** retente la soumission

### Retour

**BACK / ESC =>** retour à la page précédente / fallback

---

# Cas 4 — Dialog "Utiliser cette source ?"

## Général

**Entrée du focus =>** bouton **Utiliser**  
**Mémoire du focus au retour =>** oui, retour sur le bouton **Ajouter la source** si le dialog est fermé sans activation  
**Fallback =>** bouton **Plus tard**  
**Retour global =>** ferme le dialog

## Apparence du focus

### Bouton "Utiliser"
- c’est un **FilledButton**
- **Focus =>** **contour blanc**

### Bouton "Plus tard"
- bouton secondaire texte
- focus clair mais plus discret que l’action principale

### Fond derrière
- inactif tant que le dialog est ouvert

---

## Bouton "Utiliser"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Plus tard**  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active immédiatement la source et redirige vers le bootstrap

### Retour

**BACK / ESC =>** ferme le dialog

---

## Bouton "Plus tard"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Utiliser**  

### Validation / action

**CLICK / OK / ENTER =>** ferme le dialog sans activer immédiatement la source

### Retour

**BACK / ESC =>** ferme le dialog