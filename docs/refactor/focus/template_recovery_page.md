# FICHE : Pin Recovery

## 1) Contexte
**Page :** Pin Recovery  
**Couverture :** Header, demande de code, saisie du code, nouveau PIN, confirmation du PIN, vérification, renvoi du code, reset final

## 2) Audit UI réel avant fiche

### Structure visible confirmée
La page affiche :

- un **header** avec :
  - bouton **Retour**
  - titre
- un texte descriptif
- selon l’état du flow :
  - soit un bouton **Demander un code**
  - soit un champ **Code**
  - puis un bouton **Vérifier**
  - puis un bouton texte **Renvoyer**
  - puis, après vérification réussie :
    - champ **Nouveau PIN**
    - champ **Confirmer le PIN**
    - bouton **Réinitialiser**
- un message d’erreur texte peut apparaître
- après succès de reset :
  - la page se ferme automatiquement

### Point important
Le code de navigation directionnelle est explicite et confirme :

- focus d’entrée dynamique selon l’état
- navigation **strictement verticale**
- très peu de navigation latérale
- `BACK / ESC` ferme la page
- le bouton **Renvoyer** est bien focusable
- le bouton **Demander un code** est seul dans son état initial

---

# Cas 1 — État initial, avant demande de code

## Général

**Entrée du focus =>** bouton **Demander un code**  
**Mémoire du focus au retour =>** non  
**Fallback =>** bouton **Demander un code**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- composant header back
- **Focus => fond grisé**
- **pas de contour**

### Bouton principal
Élément concerné :
- **Demander un code**

- **Focus => contour blanc**
- c’est l’action principale de la page dans cet état

### Texte descriptif / message
- non focusables
- purement informatifs

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Demander un code**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Demander un code"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** lance l’envoi du code de récupération

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 2 — Code demandé, étape de vérification

## Général

**Entrée du focus =>** champ **Code**  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si encore visible  
**Fallback =>** champ **Code**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Bouton retour
- **Focus => fond grisé**
- **pas de contour**

### Input "Code"
- **Focus =>** focus natif du champ
- recommandation UI :
  - halo clair ou bordure accent discrète autour du champ focusé

### Bouton principal "Vérifier"
- **Focus => contour blanc**

### Bouton texte "Renvoyer"
- **Focus =>** texte / zone du bouton mise en avant
- pas un bouton primaire
- doit rester clairement focusable

### Message d’erreur
- informatif
- non focusable

---

## Bouton "Back"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** champ **Code**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** retour à la page précédente

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Input "Code"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** bouton **Vérifier**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ  
**Soumission clavier =>** lance **Vérifier** si on n’est pas encore vérifié

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Vérifier"

### Comportement attendu par action

**UP ↑ =>** champ **Code**  
**DOWN ↓ =>** bouton **Renvoyer**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** vérifie le code saisi

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Renvoyer"

### Comportement attendu par action

**UP ↑ =>** bouton **Vérifier**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** renvoie un code si autorisé par le cooldown

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 3 — Code vérifié, saisie du nouveau PIN

## Général

**Entrée du focus =>** champ **Nouveau PIN**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** champ **Nouveau PIN**  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Input "Code"
- peut encore être visible mais désactivé
- ne doit plus sembler éditable

### Input "Nouveau PIN"
- **Focus =>** focus natif du champ
- halo clair ou bordure accent discrète recommandée

### Input "Confirmer le PIN"
- **Focus =>** focus natif du champ
- même logique visuelle que le champ précédent

### Bouton principal "Réinitialiser"
- **Focus => contour blanc**

### Message d’erreur
- informatif
- non focusable

---

## Input "Code" (visible mais déjà validé)

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** champ **Nouveau PIN**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** aucune modification utile si le champ est désactivé

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Input "Nouveau PIN"

### Comportement attendu par action

**UP ↑ =>** bouton **Back**  
**DOWN ↓ =>** champ **Confirmer le PIN**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ  
**Soumission clavier =>** passe au champ **Confirmer le PIN**

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Input "Confirmer le PIN"

### Comportement attendu par action

**UP ↑ =>** champ **Nouveau PIN**  
**DOWN ↓ =>** bouton **Réinitialiser**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** active l’édition du champ  
**Soumission clavier =>** lance la réinitialisation

### Retour

**BACK / ESC =>** retour à la page précédente

---

## Bouton "Réinitialiser"

### Comportement attendu par action

**UP ↑ =>** champ **Confirmer le PIN**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** lance la réinitialisation du PIN

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 4 — Envoi / vérification / reset en cours

## Général

**Entrée du focus =>** conserve le focus courant si possible  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton principal de l’étape courante  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Boutons principaux
- gardent leur place visuelle
- si `loading`, le spinner du bouton est informatif
- le focus du bouton principal reste :
  - **contour blanc**

### Inputs désactivés
- ne doivent plus donner l’impression d’être modifiables

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

**CLICK / OK / ENTER =>** aucune nouvelle action si l’élément est désactivé ; sinon action normale

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 5 — Erreur de formulaire / erreur de statut

## Général

**Entrée du focus =>** dernier élément utile de l’étape courante :
- bouton **Vérifier**
- ou bouton **Réinitialiser**
- ou champ concerné

**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton principal de l’étape active  
**Retour global =>** retour à la page précédente

## Apparence du focus

### Élément de correction
- garde son focus normal :
  - input = focus natif
  - bouton principal = contour blanc

### Message d’erreur
- texte rouge
- informatif
- non focusable

### Bouton retour
- **fond grisé**
- **pas de contour**

---

## Élément principal de l’étape

### Comportement attendu par action

**UP ↑ =>** navigation normale de l’étape  
**DOWN ↓ =>** navigation normale de l’étape  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

### Validation / action

**CLICK / OK / ENTER =>** retente l’action après correction éventuelle

### Retour

**BACK / ESC =>** retour à la page précédente

---

# Cas 6 — Succès de reset

## Général

**Entrée du focus =>** non applicable, la page se ferme automatiquement  
**Mémoire du focus au retour =>** retour à l’élément qui a ouvert la page  
**Fallback =>** non applicable  
**Retour global =>** non applicable une fois la page fermée

## Apparence du focus

### Page de retour
- doit idéalement restaurer le focus sur l’élément qui a ouvert **Pin Recovery**

### Écran courant
- pas de nouvel état interactif durable
- fermeture automatique après succès

## Après succès

### Comportement attendu

**CLICK / OK / ENTER =>** non applicable  
**BACK / ESC =>** non applicable, la page s’est fermée