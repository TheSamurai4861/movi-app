# FICHE : Settings

## 1) Contexte
**Page :** Settings  
**Couverture :** Profils, tile Premium, sections IPTV, lecture, général, cloud sync, aide & diagnostic

---

# Cas 1 — Desktop / TV, état principal chargé

## Général

**Entrée du focus =>** premier profil  
**Mémoire du focus au retour =>** oui, sur le dernier élément focusé si il existe encore  
**Fallback =>** premier profil, sinon bouton **Ajouter un profil**, sinon tile **Premium**, sinon premier item de réglage  
**Retour global =>** retour vers l’icône **Settings** du shell latéral

## Apparence du focus

### Profil
- **Focus =>** contour blanc autour du cercle / avatar
- le profil sélectionné et le profil focusé doivent rester distinguables

### Bouton icône / switch
- **Focus =>** **fond grisé**
- **pas de contour**

### Tile Premium
- **Focus =>** carte entière mise en avant avec contour visible
- elle doit être perçue comme une destination forte

### Item de réglage
- **Focus =>** ligne entière mise en avant
- idéalement :
  - fond légèrement renforcé
  - contour clair discret
  - chevron / valeur / trailing restent visibles

### Bouton primaire éventuel
- **Focus =>** **contour blanc**

---

## Premier profil

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** tile **Premium**  
**LEFT ← =>** retour vers l’icône **Settings** du shell latéral  
**RIGHT → =>** profil suivant si il existe, sinon bouton **Ajouter un profil**  

### Validation / action

**CLICK / OK / ENTER =>** sélectionne / ouvre la gestion du profil  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  

---

## Profil intermédiaire

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** tile **Premium**  
**LEFT ← =>** profil précédent  
**RIGHT → =>** profil suivant si il existe, sinon bouton **Ajouter un profil**  

### Validation / action

**CLICK / OK / ENTER =>** sélectionne / ouvre la gestion du profil  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  

---

## Bouton "Ajouter un profil"

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** tile **Premium**  
**LEFT ← =>** dernier profil si il existe, sinon retour vers l’icône **Settings** du shell latéral  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le dialog de création de profil  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  

---

## Tile "Premium"

### Comportement attendu par action

**UP ↑ =>** premier profil  
**DOWN ↓ =>** premier item de la section **IPTV**  
**LEFT ← =>** retour vers l’icône **Settings** du shell latéral  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la page / le détail Premium  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  

---

## Item de réglage standard

### Comportement attendu par action

**UP ↑ =>** item précédent de la liste, sinon tile **Premium**  
**DOWN ↓ =>** item suivant de la liste si il existe, sinon item suivant de la section suivante  
**LEFT ← =>** retour vers l’icône **Settings** du shell latéral  
**RIGHT → =>** va vers le contrôle trailing si il existe et qu’il est focusable, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre la sous-page, le sélecteur ou exécute l’action liée à l’item  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  

---

## Contrôle trailing (sélecteur / dropdown / valeur focusable)

### Comportement attendu par action

**UP ↑ =>** item de réglage au-dessus  
**DOWN ↓ =>** item de réglage au-dessous  
**LEFT ← =>** item parent  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ouvre le sélecteur associé  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  

---

## Switch "Cloud Sync Auto"

### Comportement attendu par action

**UP ↑ =>** item précédent  
**DOWN ↓ =>** item suivant  
**LEFT ← =>** item parent  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active / désactive le switch  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  

---

# Cas 3 — Dialog "Créer un profil"

## Général

**Entrée du focus =>** premier champ du dialog  
**Mémoire du focus au retour =>** oui, retour sur **Ajouter un profil**  
**Fallback =>** premier champ  
**Retour global =>** ferme le dialog

## Apparence du focus

### Champ
- **Focus =>** bordure accent autour du champ

### Bouton primaire
- **Focus =>** **contour blanc**

### Bouton secondaire
- **Focus =>** fond légèrement renforcé ou contour discret

## Premier champ

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** champ suivant ou bouton primaire  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** active la saisie  

### Retour

**BACK / ESC =>** ferme le dialog  

---

## Bouton primaire "Créer"

### Comportement attendu par action

**UP ↑ =>** dernier champ  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton secondaire si il existe  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** crée le profil  

### Retour

**BACK / ESC =>** ferme le dialog  

---

## Bouton secondaire "Annuler"

### Comportement attendu par action

**UP ↑ =>** dernier champ  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton primaire  

### Validation / action

**CLICK / OK / ENTER =>** annule et ferme le dialog  

### Retour

**BACK / ESC =>** ferme le dialog  

---

# Cas 4 — Dialog / menu "Gérer un profil"

## Général

**Entrée du focus =>** première action disponible  
**Mémoire du focus au retour =>** oui, retour sur le profil concerné  
**Fallback =>** première action  
**Retour global =>** ferme le dialog / menu

## Apparence du focus

### Action du menu
- **Focus =>** ligne entière mise en avant

### Bouton primaire
- **Focus =>** **contour blanc**

### Bouton icône éventuel
- **Focus =>** **fond grisé**
- **pas de contour**

## Action du menu

### Comportement attendu par action

**UP ↑ =>** action précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** action suivante si elle existe, sinon bouton **Cancel** si présent  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** exécute l’action sélectionnée  

### Retour

**BACK / ESC =>** ferme le dialog / menu  

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière action  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ferme le dialog / menu  

### Retour

**BACK / ESC =>** ferme le dialog / menu  

---

# Cas 5 — Sélecteur TV / desktop (langue, accent, qualité, audio, sous-titres, fréquence)

## Général

**Entrée du focus =>** option actuellement sélectionnée si possible, sinon première option  
**Mémoire du focus au retour =>** oui, retour sur l’item de réglage qui a ouvert le sélecteur  
**Fallback =>** première option  
**Retour global =>** ferme le sélecteur

## Apparence du focus

### Option
- **Focus =>** ligne entière mise en avant
- l’option sélectionnée et l’option focusée doivent rester distinguables

### Bouton "Cancel"
- **Focus =>** fond renforcé ou contour discret

### Bouton primaire éventuel
- **Focus =>** **contour blanc**

## Option

### Comportement attendu par action

**UP ↑ =>** option précédente si elle existe, sinon bloqué  
**DOWN ↓ =>** option suivante si elle existe, sinon bouton **Cancel**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** applique l’option sélectionnée  

### Retour

**BACK / ESC =>** ferme le sélecteur  

---

## Bouton "Cancel"

### Comportement attendu par action

**UP ↑ =>** dernière option  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué  

### Validation / action

**CLICK / OK / ENTER =>** ferme le sélecteur  

### Retour

**BACK / ESC =>** ferme le sélecteur  

---

# Cas 6 — Chargement / erreur des profils

## Général

**Entrée du focus =>** premier élément disponible :
- profil de retry si présent
- sinon bouton **Ajouter un profil**
- sinon premier item de réglage

**Mémoire du focus au retour =>** non  
**Fallback =>** premier élément disponible  
**Retour global =>** retour vers l’icône **Settings** du shell latéral

## Apparence du focus

### Élément de récupération
- si un profil / cercle de recovery est affiché
- **Focus =>** contour blanc autour du cercle

### Bouton icône
- **Focus =>** **fond grisé**
- **pas de contour**

### Item standard
- **Focus =>** ligne entière mise en avant

## Élément de récupération

### Comportement attendu par action

**UP ↑ =>** bloqué  
**DOWN ↓ =>** zone suivante disponible  
**LEFT ← =>** retour vers l’icône **Settings** du shell latéral si pertinent, sinon bloqué  
**RIGHT → =>** élément voisin si il existe, sinon bloqué  

### Validation / action

**CLICK / OK / ENTER =>** relance le chargement / rafraîchit les profils  

### Retour

**BACK / ESC =>** retour vers l’icône **Settings** du shell latéral  