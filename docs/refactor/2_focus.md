# PRD — Refactor du système de focus

## 1. Contexte

Le projet dispose déjà d’un socle focus fonctionnel, avec plusieurs briques dédiées :

- `lib/src/core/focus/movi_route_focus_boundary.dart`
- `lib/src/core/focus/movi_overlay_focus_scope.dart`
- `lib/src/core/widgets/movi_focusable.dart`
- `lib/src/features/shell/presentation/providers/shell_providers.dart`
- plusieurs pages qui implémentent des règles locales de navigation focus (`search_page.dart`, `welcome_source_page.dart`, `welcome_user_page.dart`, `settings_subtitles_page.dart`, `sidebar_nav.dart`, etc.)

L’existant n’est pas désastreux : il gère déjà la création durable de `FocusNode`, la restauration partielle du focus, l’entrée de focus dans certaines zones, et des comportements TV / desktop explicites.

Le problème principal n’est pas l’absence de solution, mais la **dispersion de la décision de focus** entre plusieurs couches et plusieurs widgets.

Cela crée progressivement :

- une logique de navigation difficile à suivre,
- des effets de bord implicites,
- des responsabilités mélangées,
- un coût croissant pour ajouter ou corriger une règle de focus,
- un risque accru de bugs subtils de restauration, de perte ou de saut de focus.

Ce PRD définit la cible du refactor, son périmètre, les livrables attendus, et le plan de migration incrémental.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. **Décision de focus répartie dans trop d’endroits**
   - shell,
   - boundary de route,
   - overlays,
   - widgets focusables,
   - pages métier,
   - handlers directionnels locaux.

2. **Navigation trop impérative**
   - appels `requestFocus()` dispersés,
   - usage récurrent de `addPostFrameCallback(...)`,
   - logique “si gauche alors…” codée localement dans plusieurs pages.

3. **Responsabilités mélangées**
   - certains composants gèrent à la fois rendu visuel, activation, visibilité scrollée et règles de navigation,
   - certaines pages gèrent à la fois logique métier, layout et graphes de navigation focus.

4. **Faible lisibilité du comportement global**
   - il est difficile de répondre rapidement à des questions comme :
     - “où va le focus quand on sort à gauche de cette page ?”
     - “quelle est l’entrée primaire de cette section ?”
     - “que restaure-t-on à la fermeture d’un overlay ?”

5. **Maintenabilité insuffisante à moyen terme**
   - chaque nouvelle règle augmente le couplage,
   - les régressions focus deviennent plus probables,
   - les tests sont difficiles à cibler.

### 2.2 Causes racines

- absence d’un langage commun explicite pour décrire les zones de focus,
- absence d’un orchestrateur unique des transitions structurelles,
- couplage direct entre pages / shell / nœuds concrets,
- logique déclarative insuffisante pour les entrées, sorties et restaurations,
- mélange entre focus structurel, focus de page et focus local de composant.

---

## 3. Objectifs

### 3.1 Objectif principal

Refactorer le système de focus pour obtenir une architecture **plus simple, plus lisible, plus testable et plus robuste**, sans réécriture massive ni rupture fonctionnelle.

### 3.2 Objectifs détaillés

1. **Centraliser la décision de focus structurel**
   - shell ↔ contenu,
   - entrée de page,
   - sortie de page,
   - entrée / sortie d’overlay,
   - restauration entre zones.

2. **Rendre explicites les régions de focus**
   - nommer les zones,
   - décrire leurs points d’entrée,
   - décrire leurs sorties directionnelles.

3. **Réduire le focus impératif dispersé**
   - diminuer les appels ad hoc à `requestFocus()`,
   - réduire les callbacks locaux qui décident de la navigation globale.

4. **Séparer clairement les responsabilités**
   - structure de navigation focus,
   - logique de page,
   - rendu et interaction locale des composants focusables.

5. **Permettre une migration incrémentale**
   - sans freeze du produit,
   - sans réécriture totale,
   - avec compatibilité transitoire.

6. **Améliorer la testabilité**
   - tests unitaires du graphe de navigation,
   - tests ciblés des restaurations,
   - tests d’intégration des flux critiques.

---

## 4. Hors périmètre

Ne font pas partie de ce refactor, sauf ajustement strictement nécessaire :

- refonte visuelle complète des composants focusables,
- refonte du shell ou du système de navigation applicative,
- changement global du state management,
- optimisation micro-performance non justifiée par mesure,
- redesign UX des écrans,
- refonte métier des pages Search / Welcome / Settings.

Le focus de ce chantier est **l’architecture du focus**, pas une réécriture fonctionnelle générale.

---

## 5. Principes directeurs

Le refactor doit respecter strictement les bonnes pratiques du projet :

- simplicité avant sophistication,
- frontières d’architecture nettes,
- séparation claire des responsabilités,
- réduction des effets de bord cachés,
- peu d’état global implicite,
- flux explicites,
- refactor incrémental et sécurisé,
- pas d’abstraction prématurée,
- pas de framework interne inutilement générique.

En conséquence, la solution cible doit être :

- **centrée sur le besoin réel du projet**,
- **compréhensible rapidement**,
- **modulaire sans sur-abstraction**,
- **progressivement adoptable**,
- **testable sans environnement complet**.

---

## 6. Architecture cible

## 6.1 Vision d’ensemble

Le système cible est organisé autour de **trois niveaux de responsabilité**.

### Niveau 1 — Focus structurel d’application

Responsabilité :

- gérer les transitions entre grandes zones de l’application,
- coordonner shell, contenu, routes et overlays,
- définir l’entrée primaire d’une région,
- restaurer le dernier focus valide d’une région,
- résoudre les sorties de bord entre régions.

Cette couche ne connaît pas les détails fins d’une grille ou d’un formulaire.

### Niveau 2 — Focus de page / section

Responsabilité :

- déclarer les régions exposées par une page,
- déclarer leurs entrées,
- déclarer leurs sorties,
- définir les relations entre régions d’une même page.

Cette couche exprime un **plan de navigation**, pas une suite de décisions impératives dispersées.

### Niveau 3 — Focus local de composant

Responsabilité :

- gérer le rendu focusé / hover / pressed,
- gérer l’activation locale,
- assurer éventuellement le `ensureVisible`,
- gérer des comportements locaux simples.

Cette couche ne décide pas des transitions structurelles globales.

---

## 6.2 Concepts cibles

### 6.2.1 FocusRegionId

Chaque grande zone focusable significative du produit est identifiée par un identifiant métier stable.

Exemples cibles :

- `shellSidebar`
- `homePrimary`
- `searchInput`
- `searchFilters`
- `searchResultsMovies`
- `searchResultsSeries`
- `welcomePrimary`
- `settingsSubtitlesPrimary`
- `dialogPrimary`

Objectif : raisonner en termes de **régions de focus**, pas directement en termes de `FocusNode` dispersés.

### 6.2.2 FocusRegionBinding

Une région fournit un contrat d’entrée explicite :

- `primaryEntryNode`
- `fallbackEntryNode`
- `restoreLastFocusedNode`

Ce binding représente le point d’entrée officiel de la région.

### 6.2.3 DirectionalEdge

Un vocabulaire commun doit être introduit pour les sorties directionnelles :

- `left`
- `right`
- `up`
- `down`
- `back`

### 6.2.4 Exit map

Chaque région peut déclarer une carte de sortie :

- si sortie par `left` → région cible,
- si sortie par `back` → région cible,
- etc.

Cette carte évite les callbacks spécialisés couplés au shell.

### 6.2.5 FocusOrchestrator

Le système cible introduit un orchestrateur unique des transitions structurelles.

Responsabilités :

- enregistrer / désenregistrer les régions actives,
- mémoriser le dernier `FocusNode` valide par région,
- exécuter l’entrée dans une région,
- résoudre les sorties entre régions,
- appliquer une stratégie de restauration cohérente,
- fournir des logs de diagnostic en debug.

---

## 6.3 Découpage de module cible

Structure cible recommandée :

```text
lib/src/core/focus/
  application/
    focus_orchestrator.dart
    default_focus_orchestrator.dart
  domain/
    app_focus_region_id.dart
    directional_edge.dart
    focus_region_binding.dart
    focus_region_exit_map.dart
    focus_restore_strategy.dart
  presentation/
    focus_region_scope.dart
    focus_overlay_scope.dart
    movi_focusable_action.dart
    movi_ensure_visible_on_focus.dart
  infrastructure/
    focus_registry.dart
    focus_debug_logger.dart
```

### Règles d’architecture associées

- `domain` : concepts purs, sans dépendance UI Flutter inutile,
- `application` : orchestration des transitions,
- `presentation` : widgets Flutter qui exposent ces concepts,
- `infrastructure` : runtime, diagnostics, stockage technique si nécessaire.

---

## 7. Cible de refactor des composants existants

## 7.1 `ShellFocusCoordinator`

### Situation actuelle

`ShellFocusCoordinator` mélange plusieurs rôles :

- binding des entrées par onglet,
- mémorisation du dernier focus du contenu,
- focus sidebar,
- focus entry / primary / fallback.

### Cible

Le shell doit rester une **façade simple** sur l’orchestrateur, limitée au shell.

### Nouveau rôle attendu

- attacher / détacher la région sidebar,
- demander le focus de la sidebar,
- demander l’entrée de la région principale de l’onglet actif,
- déléguer les décisions structurelles à l’orchestrateur.

### À éviter après refactor

- registry global opportuniste des `FocusNode` de tout le produit,
- connaissance directe des détails internes des pages,
- multiplication des chemins alternatifs shell → page.

---

## 7.2 `MoviRouteFocusBoundary`

### Situation actuelle

Le boundary :

- mémorise le dernier descendant focusé,
- gère certains événements clavier,
- délègue via `onUnhandledLeft` / `onUnhandledBack`,
- peut demander un focus d’entrée au montage.

### Cible

Le composant devient un **`FocusRegionScope` déclaratif**.

### Responsabilités cibles

- enregistrer une région auprès de l’orchestrateur,
- mémoriser le dernier descendant focusé de cette région,
- exposer une `exitMap`,
- demander une entrée si explicitement prévu,
- déléguer les transitions à l’orchestrateur.

### Bénéfice

Le boundary ne connaît plus directement la sidebar ni des callbacks ad hoc. Il décrit la région et ses sorties.

---

## 7.3 `MoviOverlayFocusScope`

### Situation actuelle

Le scope overlay :

- crée son `FocusScopeNode`,
- prend un focus initial,
- tente de restaurer le trigger ou un fallback à la fermeture.

### Cible

Conserver le principe, mais l’aligner sur le modèle des régions.

### Responsabilités cibles

- enregistrer une région temporaire d’overlay,
- demander son entrée primaire,
- piéger le focus dans l’overlay,
- restaurer le focus vers la région d’origine ou le trigger à la fermeture,
- ne jamais connaître la navigation interne de la page sous-jacente.

### Règle de fermeture cible

Ordre de restitution :

1. trigger valide,
2. région d’origine,
3. fallback explicite,
4. fallback shell si nécessaire.

---

## 7.4 `MoviFocusableAction`

### Situation actuelle

Le composant gère ensemble :

- focus/hover/pressed,
- activation,
- éventuellement `ensureVisible`,
- aspects sémantiques.

### Cible

Scinder en deux responsabilités :

#### `MoviFocusableAction`
Gère :
- rendu interactif,
- focus visuel,
- hover,
- pressed,
- activation,
- sémantique.

#### `MoviEnsureVisibleOnFocus`
Gère :
- l’effet de bord `Scrollable.ensureVisible(...)` lors d’un focus,
- la politique de visibilité,
- l’alignement vertical si nécessaire.

### Bénéfice

- code plus lisible,
- effet de bord isolé,
- réglage plus simple,
- testabilité améliorée.

---

## 8. Stratégie par type d’écran

## 8.1 Shell

Le shell devient la couche qui décide uniquement de la **région structurelle active**.

Exemples de responsabilités du shell :

- entrée focus sidebar,
- transfert sidebar → région primaire de l’onglet actif,
- retour d’une page vers la sidebar si la carte de sortie le prévoit,
- fallback structurel si aucune région de contenu valide n’est disponible.

Le shell ne doit pas connaître les `FocusNode` internes des pages au-delà de leur contrat de région.

---

## 8.2 Pages métier

Chaque page doit définir explicitement :

- ses régions,
- leur entrée primaire,
- leur fallback,
- leurs sorties de bord,
- les règles de restauration utiles.

### Exemples de pages prioritaires

- `search_page.dart`
- `welcome_source_page.dart`
- `welcome_user_page.dart`
- `settings_subtitles_page.dart`

Ces pages semblent actuellement contenir une part significative de navigation focus impérative et doivent être migrées en priorité.

---

## 8.3 Overlays / dialogs / sheets

Tout overlay doit suivre une convention unique :

- capture de la région ou du trigger d’origine,
- création d’une région temporaire,
- entrée primaire explicite,
- restitution cohérente à la fermeture,
- aucun couplage à la navigation de fond.

---

## 9. Flux cibles de navigation

## 9.1 Sidebar → contenu

1. utilisateur sur la sidebar,
2. action droite,
3. le shell demande l’entrée de la région primaire de l’onglet actif,
4. l’orchestrateur restaure le dernier nœud valide de cette région si disponible,
5. sinon il utilise l’entrée primaire,
6. sinon le fallback.

## 9.2 Contenu → sidebar

1. une région de contenu ne résout pas localement une sortie `left` ou `back`,
2. son `exitMap` pointe vers `shellSidebar`,
3. l’orchestrateur exécute la transition,
4. la sidebar récupère le focus.

## 9.3 Ouverture d’un overlay

1. capture du contexte d’origine,
2. enregistrement de la région temporaire d’overlay,
3. entrée primaire overlay,
4. focus piégé dans l’overlay,
5. à la fermeture, restitution selon la politique de retour.

## 9.4 Revenir sur une page

1. l’utilisateur revient sur une région de page,
2. si la stratégie de restauration l’autorise et qu’un nœud valide est connu, il est restauré,
3. sinon on retombe sur l’entrée primaire,
4. sinon fallback.

---

## 10. Exigences fonctionnelles

### 10.1 Exigences obligatoires

1. Une page ou section importante doit pouvoir déclarer une région focusable nommée.
2. Une région doit pouvoir définir une entrée primaire et un fallback.
3. Une région doit pouvoir mémoriser le dernier nœud focusé valide.
4. Une région doit pouvoir déclarer des sorties directionnelles.
5. Le shell doit pouvoir demander l’entrée primaire d’un onglet sans connaître ses détails internes.
6. Les overlays doivent pouvoir restaurer le focus à la fermeture de manière déterministe.
7. Les transitions structurelles doivent passer par un orchestrateur unique.
8. Le système doit supporter une migration progressive écran par écran.

### 10.2 Exigences ergonomiques

1. Le comportement doit rester cohérent entre TV et desktop.
2. Les entrées primaires doivent être explicites et stables.
3. Les sorties latérales et back doivent rester prévisibles.
4. Aucun écran ne doit “perdre” le focus sans fallback clair.

---

## 11. Exigences non fonctionnelles

## 11.1 Lisibilité

- la navigation focus doit être compréhensible rapidement,
- les points d’entrée et de sortie doivent être identifiables sans lire tout l’écran,
- les noms doivent refléter l’intention.

## 11.2 Maintenabilité

- ajout d’une nouvelle région sans toucher plusieurs couches non concernées,
- changement local sans effet domino majeur,
- réduction du couplage entre shell et pages.

## 11.3 Testabilité

- l’orchestrateur doit être testable indépendamment de l’UI complète,
- les cartes de sortie doivent être testables,
- les restaurations doivent être vérifiables de manière déterministe.

## 11.4 Performance

- pas de recréation intempestive de `FocusNode`,
- pas de travail inutile dans `build()`,
- pas d’explosion des callbacks de restitution,
- `ensureVisible` isolé et contrôlable.

## 11.5 Robustesse

- vérification systématique de validité des nœuds avant `requestFocus()`,
- fallback explicite quand un nœud n’est plus monté,
- comportement stable à l’ouverture / fermeture des overlays,
- absence de boucle de restauration focus.

---

## 12. Plan de migration

La migration doit être **progressive**.

## Étape 1 — Introduire le langage commun

### Livrables

- `app_focus_region_id.dart`
- `directional_edge.dart`
- `focus_region_binding.dart`
- types minimaux de stratégie de restauration

### Objectif

Fournir une base commune sans casser l’existant.

### Résultat attendu

Le projet dispose d’un vocabulaire stable pour parler des régions et des transitions.

---

## Étape 2 — Introduire `FocusOrchestrator`

### Livrables

- interface `focus_orchestrator.dart`
- implémentation par défaut `default_focus_orchestrator.dart`
- éventuellement un `focus_registry.dart`

### Objectif

Centraliser l’entrée dans les régions, la mémorisation et les transitions.

### Compatibilité

Le shell peut continuer à utiliser temporairement ses bindings existants via un adaptateur.

---

## Étape 3 — Adapter le shell

### Livrables

- refactor de `ShellFocusCoordinator` en façade shell,
- branchement sur l’orchestrateur,
- conservation temporaire d’API de compatibilité si nécessaire.

### Objectif

Faire du shell un consommateur simple du moteur de focus, pas un registry global.

---

## Étape 4 — Remplacer `MoviRouteFocusBoundary`

### Livrables

- nouveau `FocusRegionScope`,
- adaptation progressive des pages qui utilisent les anciens callbacks,
- support d’une `exitMap`.

### Objectif

Passer d’un boundary impératif à une déclaration de région.

---

## Étape 5 — Refactor des overlays

### Livrables

- refactor de `MoviOverlayFocusScope`,
- politique de restitution homogène,
- harmonisation avec les régions.

### Objectif

Stabiliser les comportements d’ouverture / fermeture.

---

## Étape 6 — Découpage de `MoviFocusableAction`

### Livrables

- `MoviFocusableAction` simplifié,
- `MoviEnsureVisibleOnFocus` extrait,
- adaptation des usages.

### Objectif

Isoler le rendu interactif des effets de bord scroll.

---

## Étape 7 — Migration des pages prioritaires

### Ordre recommandé

1. `search_page.dart`
2. `welcome_source_page.dart`
3. `welcome_user_page.dart`
4. `settings_subtitles_page.dart`
5. `sidebar_nav.dart` si nécessaire après adaptation shell

### Objectif

Remplacer les règles focus dispersées par des plans de navigation déclaratifs.

---

## 13. Backlog de mise en œuvre détaillé

## Epic A — Socle focus

### Story A1
Créer les types domaine du focus.

### Story A2
Créer l’interface de l’orchestrateur.

### Story A3
Créer l’implémentation par défaut de l’orchestrateur.

### Story A4
Ajouter les logs debug optionnels du focus.

---

## Epic B — Intégration shell

### Story B1
Brancher la sidebar comme région focusable structurelle.

### Story B2
Brancher les onglets shell sur les régions primaires.

### Story B3
Réduire `ShellFocusCoordinator` à son rôle façade.

---

## Epic C — Boundary / scopes

### Story C1
Créer `FocusRegionScope`.

### Story C2
Migrer un premier écran pilote.

### Story C3
Créer `FocusOverlayScope` aligné sur la nouvelle architecture.

---

## Epic D — Widgets focusables

### Story D1
Extraire `MoviEnsureVisibleOnFocus`.

### Story D2
Simplifier `MoviFocusableAction`.

### Story D3
Vérifier la compatibilité UI des composants focusables existants.

---

## Epic E — Migration écrans métier

### Story E1
Définir le plan focus de `search_page.dart`.

### Story E2
Définir le plan focus de `welcome_source_page.dart`.

### Story E3
Définir le plan focus de `welcome_user_page.dart`.

### Story E4
Définir le plan focus de `settings_subtitles_page.dart`.

---

## 14. Critères d’acceptation

## 14.1 Critères d’architecture

1. Les transitions structurelles ne dépendent plus de callbacks ad hoc page → shell.
2. Le shell ne manipule plus directement les nœuds internes des pages au-delà de leur contrat de région.
3. Les écrans migrés définissent explicitement leurs régions, leurs entrées et leurs sorties.
4. Les composants focusables ne portent plus de logique de navigation structurelle globale.

## 14.2 Critères fonctionnels

1. Sidebar → contenu fonctionne sur les écrans migrés.
2. Contenu → sidebar fonctionne via les sorties déclarées.
3. La restauration de focus à la fermeture d’un overlay est cohérente et déterministe.
4. Retour sur un écran migré : restauration du dernier focus valide si prévu, sinon entrée primaire.
5. Aucun écran migré ne produit de perte silencieuse de focus.

## 14.3 Critères qualité

1. Les types et noms introduits sont explicites.
2. Les responsabilités sont clairement séparées.
3. Les comportements critiques sont couverts par tests.
4. La migration n’introduit pas de dépendances circulaires.
5. Le code reste compréhensible sans explication orale.

---

## 15. Plan de test

## 15.1 Tests unitaires

À prévoir sur :

- résolution entrée primaire / fallback,
- restauration du dernier nœud valide,
- résolution des `DirectionalEdge`,
- refus de focuser un nœud invalide,
- fallback quand la cible n’est plus montée.

## 15.2 Tests d’intégration widget

À prévoir sur :

- shell ↔ page migrée,
- page ↔ sidebar,
- overlay ↔ trigger / région d’origine,
- entrée primaire d’un écran,
- navigation latérale / verticale sur écrans ciblés.

## 15.3 Tests de non-régression manuels

Parcours minimaux :

- Home / Search / Welcome / Settings,
- ouverture / fermeture d’overlay,
- retour arrière clavier / télécommande,
- navigation TV en bord de grille,
- changement d’onglet shell.

---

## 16. Risques

### Risque 1 — Sur-abstraction

Créer un framework interne trop générique compliquerait la lecture et freinerait l’adoption.

**Réponse attendue** : rester minimal, centré sur régions + orchestrateur + scopes.

### Risque 2 — Migration incomplète hybride trop longue

Un état transitoire mal contrôlé peut créer un système où coexistent trop longtemps deux manières de faire.

**Réponse attendue** : plan de migration court, écran pilote puis migration progressive priorisée.

### Risque 3 — Régressions overlays

Les overlays sont sensibles à la restitution du focus.

**Réponse attendue** : traiter très tôt les politiques de retour et les couvrir par tests ciblés.

### Risque 4 — Couplage shell toujours présent

Si le shell continue à connaître trop de détails, le gain sera faible.

**Réponse attendue** : imposer le contrat “région” comme frontière.

### Risque 5 — Dégradation perçue de la fluidité

Un `ensureVisible` mal maîtrisé ou des callbacks supplémentaires pourraient créer du jank.

**Réponse attendue** : isoler `ensureVisible`, profiler si nécessaire, éviter le travail inutile.

---

## 17. Indicateurs de succès

Le chantier sera considéré comme réussi si :

- le nombre d’endroits qui décident du focus structurel diminue fortement,
- les écrans migrés expriment leur navigation focus de manière lisible,
- l’équipe peut répondre rapidement à “quelle est l’entrée / sortie de cette zone ?”,
- les régressions focus deviennent plus localisables,
- l’ajout d’une nouvelle section focusable devient un changement local,
- le shell n’a plus besoin de connaître les détails internes des pages.

---

## 18. Décisions de conception à retenir

1. Le focus est piloté par des **régions nommées**, pas uniquement par des `FocusNode` dispersés.
2. Les transitions structurelles passent par un **orchestrateur unique**.
3. Le shell reste une **façade**, pas un moteur global opportuniste.
4. Les pages décrivent leur **plan focus**.
5. Les composants focusables gèrent le **local**, pas le global.
6. Les overlays suivent une **politique de retour unique**.
7. La migration est **progressive**, sans réécriture totale.

---

## 19. Résultat attendu final

À l’issue du refactor, le projet doit disposer d’un système de focus qui :

- reste compatible avec les usages TV / desktop,
- réduit fortement la logique de focus dispersée,
- explicite les points d’entrée, de sortie et de restauration,
- isole les effets de bord,
- réduit le couplage shell ↔ pages,
- permet des évolutions locales sans comportement magique,
- reste simple à comprendre et à maintenir.

---

## 20. Annexe — résumé opérationnel

### En une phrase

Le refactor vise à passer d’un système de focus **dispersé et partiellement impératif** à un système **piloté par des régions nommées, un orchestrateur unique, et des scopes déclaratifs**.

### Priorités absolues

1. Introduire les régions.
2. Introduire l’orchestrateur.
3. Brancher le shell.
4. Migrer les boundaries.
5. Migrer les pages les plus complexes.
6. Découper les composants focusables.

### Écrans de migration prioritaires

- Search
- Welcome source
- Welcome user
- Settings subtitles

