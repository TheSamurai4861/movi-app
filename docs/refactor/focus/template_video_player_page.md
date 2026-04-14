# FICHE : Video Player

## 1) Contexte
**Page :** Video Player  
**Couverture :** Overlay des contrôles, rangée haute, rangée centrale, rangée basse, états avec / sans épisode suivant, avec / sans audio, avec / sans PiP

## 2) Audit UI réel avant fiche

### Structure visible confirmée
Quand les contrôles sont affichés, l’overlay du player montre :

- en haut :
  - **Back**
  - **Resize / mode d’affichage** si disponible
  - **Chromecast** si disponible
- au centre :
  - **Rewind 30**
  - **Rewind 10**
  - **Play / Pause**
  - **Forward 10**
  - **Forward 30**
- en bas :
  - **slider de progression**
  - **temps courant / durée**
  - puis une rangée d’actions :
    - **Next episode** si série
    - **Restart** si disponible
    - **Audio** si pistes audio disponibles
    - **Subtitles**
    - **PiP** si disponible

### Point important
Le code de focus est **explicite et TV-first** :

- **focus d’entrée** sur **Play / Pause**
- navigation en **3 rangées logiques**
- `LEFT / RIGHT` navigue dans la rangée
- `UP / DOWN` envoie vers le **milieu logique** de la rangée du dessus / dessous
- le **slider de progression n’a pas de FocusNode explicite ici**
  - il est visible
  - mais ce fichier ne le place pas dans la navigation directionnelle principale

### Apparence focus réelle confirmée
#### Boutons icône (`_PlayerIconAction`)
- **Focus =>**
  - fond blanc translucide renforcé
  - **contour blanc**
  - légère mise à l’échelle
- donc ici, contrairement à d’autres pages :
  - les **boutons icône ont bien un contour blanc**

#### Boutons texte (`_PlayerTextAction`)
- **Focus =>**
  - fond blanc translucide
  - **contour blanc**
  - légère mise à l’échelle

---

# Cas 1 — Overlay complet, série avec épisode suivant, restart, audio, subtitles, PiP

## Général

**Entrée du focus =>** bouton **Play / Pause**  
**Mémoire du focus au retour =>** oui, sur le dernier contrôle focusé si l’overlay est réaffiché rapidement ; sinon **Play / Pause**  
**Fallback =>** bouton **Play / Pause**  
**Retour global =>** quitte le player / revient à la page précédente via l’action `Back`

## Apparence du focus

### Boutons icône
Éléments concernés :
- **Back**
- **Resize**
- **Chromecast**
- **Rewind 30**
- **Rewind 10**
- **Play / Pause**
- **Forward 10**
- **Forward 30**
- **Audio**
- **Subtitles**
- **PiP**

- **Focus =>**
  - fond blanc translucide plus visible
  - **contour blanc**
  - léger agrandissement

### Boutons texte
Éléments concernés :
- **Next episode**
- **Restart**

- **Focus =>**
  - fond blanc translucide
  - **contour blanc**
  - légère mise en avant

### Slider
- visible
- pas de focus directionnel explicite dans ce widget
- à traiter comme **non focus principal** dans cette fiche

---

## Rangée haute

### Bouton "Back"

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Play / Pause**  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Resize** si visible, sinon bouton **Chromecast** si visible, sinon bloqué

**CLICK / OK / ENTER =>** quitte le player / revient à la page précédente  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Resize" (si visible)

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Play / Pause**  
**LEFT ← =>** bouton **Back**  
**RIGHT → =>** bouton **Chromecast** si visible, sinon bloqué

**CLICK / OK / ENTER =>** ouvre / change le mode d’affichage vidéo  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Chromecast" (si visible)

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bouton **Play / Pause**  
**LEFT ← =>** bouton **Resize** si visible, sinon bouton **Back**  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** lance l’action Chromecast  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

## Rangée centrale

### Bouton "Rewind 30"

**UP ↑ =>** bouton central de la rangée haute  
**DOWN ↓ =>** bouton central de la rangée basse  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Rewind 10**

**CLICK / OK / ENTER =>** recule de 30 secondes  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Rewind 10"

**UP ↑ =>** bouton central de la rangée haute  
**DOWN ↓ =>** bouton central de la rangée basse  
**LEFT ← =>** bouton **Rewind 30**  
**RIGHT → =>** bouton **Play / Pause**

**CLICK / OK / ENTER =>** recule de 10 secondes  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Play / Pause"

**UP ↑ =>** bouton central de la rangée haute  
**DOWN ↓ =>** bouton central de la rangée basse  
**LEFT ← =>** bouton **Rewind 10**  
**RIGHT → =>** bouton **Forward 10**

**CLICK / OK / ENTER =>** alterne lecture / pause  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Forward 10"

**UP ↑ =>** bouton central de la rangée haute  
**DOWN ↓ =>** bouton central de la rangée basse  
**LEFT ← =>** bouton **Play / Pause**  
**RIGHT → =>** bouton **Forward 30**

**CLICK / OK / ENTER =>** avance de 10 secondes  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Forward 30"

**UP ↑ =>** bouton central de la rangée haute  
**DOWN ↓ =>** bouton central de la rangée basse  
**LEFT ← =>** bouton **Forward 10**  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** avance de 30 secondes  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

## Rangée basse

### Bouton "Next episode" (si visible)

**UP ↑ =>** bouton **Play / Pause**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton **Restart** si visible, sinon **Audio** si visible, sinon **Subtitles**, sinon **PiP**

**CLICK / OK / ENTER =>** passe à l’épisode suivant  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Restart" (si visible)

**UP ↑ =>** bouton **Play / Pause**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Next episode** si visible, sinon bloqué  
**RIGHT → =>** bouton **Audio** si visible, sinon **Subtitles**, sinon **PiP**

**CLICK / OK / ENTER =>** relance la lecture depuis le début  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Audio" (si visible)

**UP ↑ =>** bouton **Play / Pause**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Restart** si visible, sinon **Next episode** si visible, sinon bloqué  
**RIGHT → =>** bouton **Subtitles**

**CLICK / OK / ENTER =>** ouvre le menu des pistes audio  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "Subtitles"

**UP ↑ =>** bouton **Play / Pause**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Audio** si visible, sinon **Restart** si visible, sinon **Next episode** si visible, sinon bloqué  
**RIGHT → =>** bouton **PiP** si visible, sinon bloqué

**CLICK / OK / ENTER =>** active / désactive les sous-titres ou ouvre leur menu selon le flux réel  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

### Bouton "PiP" (si visible)

**UP ↑ =>** bouton **Play / Pause**  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bouton **Subtitles**  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** active / désactive le mode picture-in-picture  
**BACK / ESC =>** quitte le player / revient à la page précédente

---

# Cas 2 — Overlay minimal sans rangée haute additionnelle, sans épisode suivant, sans audio, sans PiP

## Général

**Entrée du focus =>** bouton **Play / Pause**  
**Mémoire du focus au retour =>** oui  
**Fallback =>** bouton **Play / Pause**  
**Retour global =>** quitte le player / revient à la page précédente

## Apparence du focus

- identique au cas principal
- moins de boutons visibles
- le focus reste :
  - fond translucide renforcé
  - **contour blanc**
  - légère mise à l’échelle

## Séquence horizontale réelle probable

### Rangée haute
- **Back**
- éventuellement **Resize**
- éventuellement **Chromecast**

### Rangée centrale
- **Rewind 30**
- **Rewind 10**
- **Play / Pause**
- **Forward 10**
- **Forward 30**

### Rangée basse
- éventuellement **Restart**
- **Subtitles**

---

# Cas 3 — Menu Audio ouvert

## Général

**Entrée du focus =>** première piste audio disponible  
**Mémoire du focus au retour =>** oui, retour sur le bouton **Audio**  
**Fallback =>** première piste audio, sinon bouton de fermeture  
**Retour global =>** ferme le menu

## Apparence du focus

### Option audio
- **Focus =>** ligne entière mise en avant

### Bouton de fermeture
- bouton icône
- **Focus =>**
  - fond grisé / renforcé
  - **contour blanc** dans le style du player

### Option sélectionnée
- doit rester distinguable de l’option seulement focusée

---

## Première option audio

**UP ↑ =>** bouton de fermeture si visible, sinon bloqué  
**DOWN ↓ =>** option suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** sélectionne la piste audio  
**BACK / ESC =>** ferme le menu et revient sur le bouton **Audio**

---

## Option audio intermédiaire

**UP ↑ =>** option précédente  
**DOWN ↓ =>** option suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** sélectionne la piste audio  
**BACK / ESC =>** ferme le menu et revient sur le bouton **Audio**

---

## Bouton de fermeture

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première option audio  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** ferme le menu  
**BACK / ESC =>** ferme le menu

---

# Cas 4 — Menu Subtitles ouvert

## Général

**Entrée du focus =>** première option de sous-titres  
**Mémoire du focus au retour =>** oui, retour sur le bouton **Subtitles**  
**Fallback =>** première option, sinon bouton de fermeture  
**Retour global =>** ferme le menu

## Apparence du focus

### Option sous-titres
- **Focus =>** ligne entière mise en avant

### Bouton de fermeture
- style player
- **Focus => fond renforcé + contour blanc**

### Action header éventuelle "Subtitle settings"
- si visible, doit être traitée comme bouton icône / action secondaire focusable

---

## Première option sous-titres

**UP ↑ =>** bouton de fermeture ou action header si visible, sinon bloqué  
**DOWN ↓ =>** option suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** sélectionne la piste de sous-titres  
**BACK / ESC =>** ferme le menu et revient sur **Subtitles**

---

## Option intermédiaire

**UP ↑ =>** option précédente  
**DOWN ↓ =>** option suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** sélectionne la piste  
**BACK / ESC =>** ferme le menu

---

## Action "Subtitle settings" (si visible)

**UP ↑ =>** bloqué  
**DOWN ↓ =>** première option  
**LEFT ← =>** bloqué  
**RIGHT → =>** bouton de fermeture si visible, sinon bloqué

**CLICK / OK / ENTER =>** ouvre les réglages de sous-titres  
**BACK / ESC =>** ferme le menu

---

# Cas 5 — Menu Video Fit Mode ouvert

## Général

**Entrée du focus =>** option actuellement sélectionnée si possible, sinon première option  
**Mémoire du focus au retour =>** oui, retour sur le bouton **Resize**  
**Fallback =>** première option  
**Retour global =>** ferme le menu

## Apparence du focus

### Option
- **Focus =>** ligne entière mise en avant

### Option sélectionnée
- reste distinguable de l’option focusée

### Bouton de fermeture éventuel
- style player
- **Focus => fond renforcé + contour blanc**

---

## Option de fit mode

**UP ↑ =>** option précédente si elle existe, sinon bouton de fermeture éventuel  
**DOWN ↓ =>** option suivante si elle existe, sinon bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** applique le mode d’affichage vidéo  
**BACK / ESC =>** ferme le menu et revient sur **Resize**

---

# Cas 6 — Contrôles masqués / overlay absent

## Général

**Entrée du focus =>** aucun focus visible  
**Mémoire du focus au retour =>** au prochain affichage des contrôles, retour sur **Play / Pause** ou dernier contrôle mémorisé selon l’implémentation voulue  
**Fallback =>** aucun tant que l’overlay est masqué  
**Retour global =>** selon la logique page : peut réafficher les contrôles ou quitter via raccourci global

## Apparence du focus

- aucun élément de contrôle n’est visible
- aucun focus ne doit être perçu
- la vidéo seule reste affichée

## Zone player sans overlay

**UP ↑ =>** bloqué  
**DOWN ↓ =>** bloqué  
**LEFT ← =>** bloqué  
**RIGHT → =>** bloqué

**CLICK / OK / ENTER =>** réaffiche les contrôles si la logique du player le prévoit  
**BACK / ESC =>** quitte le player / revient à la page précédente si géré au niveau page