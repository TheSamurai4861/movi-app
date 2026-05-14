# Phase 4 - UI boot et composants

## Objectif

Implementer les ecrans boot issus de la specification Figma en reutilisant les
composants existants quand ils sont adaptes.

Cette phase ne doit pas redefinir les decisions de boot. Elle consomme les
contrats stabilises en phases 1, 2 et 3 :

- `BootScreenModel` decrit l'ecran a rendre ;
- `BootActionIntent` decrit les actions utilisateur ;
- `BootActionHandler` execute les actions ;
- `AppLaunchOrchestrator` reste la source de verite des transitions ;
- `LaunchRedirectGuard` applique les destinations.

## Regles de travail

- Ne pas remettre de logique catalogue dans les widgets.
- Ne pas refaire le mapping reason code -> decision dans les pages.
- Reutiliser les composants existants avant d'en creer de nouveaux.
- Le logo final doit utiliser `MoviAssetIcon` et `AppAssets.iconAppLogoSvg`.
- Les etats simples doivent garder le logo centre et le texte bas ecran hors du
  flux logo.
- Les ecrans actionnables doivent exposer une action principale focusable.
- Les variantes TV/focus doivent rester testables au clavier.
- Les pages auth/profil/source existantes restent proprietaires de la saisie
  metier.
- Les textes peuvent rester provisoirement dans le mapper si la phase 6 doit
  traiter la localisation, mais les nouveaux widgets ne doivent pas afficher de
  reason code brut.
- Toute divergence avec Figma doit etre documentee plutot que cachee.

## Etape 1 - Relecture UI et composants existants

### But

Verifier l'etat reel des composants, widgets legacy et specs Figma avant de
modifier l'UI.

### Nature

Documentation uniquement. Aucune modification de code applicatif attendue.

### Actions

- Relire la specification Figma boot.
- Relire les JSON/designs disponibles en `393x852`.
- Relire les composants existants :
  - `MoviAssetIcon` ;
  - `MoviPrimaryButton` ;
  - `AppLabeledTextField` ;
  - `ProfileAvatarChip` ;
  - `OverlaySplash` ;
  - `LaunchErrorPanel` ;
  - `LaunchRecoveryBanner`.
- Relire les modeles et mappers runtime :
  - `BootScreenModel` ;
  - `BootScreenMapper` ;
  - `BootActionHandler`.
- Identifier les composants reutilisables tels quels.
- Identifier les adaptations strictement necessaires.
- Identifier les composants a remplacer ou envelopper.

### Sortie attendue

Completer une table :

```text
composant | usage actuel | usage cible boot | adaptation requise | fichier | risque
```

### Definition de fini

- Les composants a reutiliser sont listes.
- Les ecarts Figma/composants existants sont explicites.
- Aucun composant nouveau n'est cree sans justification.

## Etape 2 - Contrat visuel `BootScreenModel -> Widget`

### But

Figer comment le modele boot devient une surface Flutter sans dupliquer les
decisions d'orchestration.

### Nature

Documentation puis implementation si le renderer n'existe pas encore.

### Actions

- Definir le renderer cible `BootScreenModel -> Widget`.
- Lister les types d'ecrans :
  - chargement simple ;
  - chargement catalogue ;
  - opening Home ;
  - action required ;
  - technical failure.
- Definir les entrees du renderer :
  - modele ;
  - callback d'action ;
  - contraintes responsive ;
  - focus initial.
- Definir les sorties :
  - widget non interactif ;
  - widget actionnable ;
  - semantic labels si necessaire.
- Verifier que le renderer ne lit pas directement l'orchestrateur.
- Verifier que le renderer ne navigue pas directement.

### Sortie attendue

Completer une table :

```text
BootScreenType | widget cible | action | focus initial | responsive | test
```

### Definition de fini

- Le renderer a une responsabilite purement presentation.
- Les actions passent par `BootActionIntent` ou `BootActionHandler`.
- Les etats non interactifs ne produisent aucune action focusable.

## Etape 3 - Widgets de chargement simple

### But

Implementer les etats de chargement simples avec logo centre et texte bas ecran.

### Nature

Implementation attendue. Cette etape peut creer des widgets boot reutilisables
et des tests widget.

### Actions

- Repartir de `OverlaySplash` ou extraire une base boot si necessaire.
- Utiliser `MoviAssetIcon`.
- Utiliser `AppAssets.iconAppLogoSvg`.
- Garantir que le logo reste centre.
- Garantir que le texte reste bas ecran.
- Couvrir les etats :
  - demarrage technique ;
  - verification session ;
  - resolution profil ;
  - resolution source ;
  - ouverture Home.
- Verifier mobile `393x852`.
- Verifier desktop avec largeur contrainte.

### Sortie attendue

Completer une table :

```text
etat | reason code | texte | widget | logo centre | texte bas | test
```

### Definition de fini

- Les etats simples existent dans Flutter.
- Le logo utilise l'asset reel.
- Le texte bas ecran n'est pas dans le meme flux layout que le logo.
- Aucun bouton n'est rendu sur ces etats.

## Etape 4 - Chargement catalogue enrichi

### But

Rendre les etats catalogue stabilises en Phase 3 sans transformer la preparation
normale en erreur utilisateur.

### Nature

Implementation attendue. Cette etape peut modifier le renderer et ajouter des
tests widget.

### Actions

- Implementer `catalog_preparing`.
- Implementer l'etat de cache catalogue pret si le modele le permet.
- Afficher une surface distincte du splash simple si Figma le demande.
- Ne pas afficher `Changer de source` pendant la preparation normale.
- Conserver une UI non interactive tant que `BootScreenModel.isInteractive` est
  false.
- Verifier les textes courts et non techniques.
- Verifier que les logs/reason codes ne sont pas affiches.

### Sortie attendue

Completer une table :

```text
etat catalogue | modele | widget | action visible | focus | test
```

### Definition de fini

- `catalog_preparing` a une surface Flutter dediee ou clairement mappee.
- Aucun bouton n'apparait pendant une attente normale.
- L'etat cached n'est pas presente comme une erreur source.

## Etape 5 - Recovery action panel

### But

Remplacer ou envelopper les surfaces legacy de recovery avec un panneau
actionnable conforme au modele boot.

### Nature

Implementation attendue. Cette etape peut modifier ou remplacer
`LaunchErrorPanel` et `LaunchRecoveryBanner`.

### Actions

- Identifier les usages actuels de `LaunchErrorPanel`.
- Identifier les usages actuels de `LaunchRecoveryBanner`.
- Definir un `BootRecoveryPanel` ou equivalent.
- Brancher :
  - titre ;
  - message ;
  - sous-message optionnel ;
  - action principale ;
  - action secondaire optionnelle.
- Mapper les recoveries :
  - erreur technique boot ;
  - source timeout ;
  - provider error ;
  - credentials invalides ;
  - catalogue vide ;
  - profil requis ;
  - source requise ;
  - selection source requise.
- Garantir focus initial sur l'action principale.
- Garantir que l'action secondaire reste atteignable au clavier.

### Sortie attendue

Completer une table :

```text
recovery | titre | action principale | action secondaire | widget | focus | test
```

### Definition de fini

- Chaque recovery critique affiche une action principale.
- Les actions utilisent les intentions boot.
- Aucun reason code brut n'est visible.
- Le focus initial pointe l'action principale.

## Etape 6 - Variantes de composants boot

### But

Adapter les composants existants seulement quand les contraintes boot/Figma le
necessitent.

### Nature

Implementation attendue si les composants actuels ne couvrent pas les besoins.

### Actions

- Evaluer `MoviPrimaryButton` :
  - largeur mobile ;
  - hauteur ;
  - radius ;
  - focus TV ;
  - etat disabled/loading si necessaire.
- Evaluer `AppLabeledTextField` :
  - radius ;
  - hauteur ;
  - padding ;
  - couleurs ;
  - focus.
- Evaluer `ProfileAvatarChip` :
  - avatar initiale ;
  - nom ;
  - selection ;
  - focus.
- Ajouter une variante boot uniquement si une prop simple ne suffit pas.
- Eviter de casser les usages hors boot.

### Sortie attendue

Completer une table :

```text
composant | ecart Figma | solution | API ajoutee | impact hors boot | test
```

### Definition de fini

- Les variantes necessaires existent.
- Les composants hors boot ne regressent pas.
- Les etats focus restent visibles.

## Etape 7 - Pages d'action raccordees

### But

Aligner les pages auth/profil/source sur le style boot sans leur retirer la
responsabilite de saisie metier.

### Nature

Implementation progressive attendue. Cette etape peut modifier les pages
existantes et ajouter des tests widget cibles.

### Actions

- Revoir les pages :
  - connexion ;
  - inscription ;
  - mot de passe oublie ;
  - creation profil ;
  - selection profil ;
  - ajout source ;
  - selection source.
- Remplacer seulement les composants visuels necessaires.
- Conserver les controllers et validations metier existants.
- Verifier que les sorties success/failure restent raccordees au tunnel boot.
- Verifier les contraintes desktop :
  - largeur de contenu contrainte ;
  - formulaires pas trop larges.
- Verifier focus TV sur les actions principales.

### Sortie attendue

Completer une table :

```text
page | composant remplace | logique conservee | action boot | responsive | test
```

### Definition de fini

- Les pages d'action gardent leur logique metier.
- Le style boot est coherent sur les pages critiques.
- Les actions restent focusables.

## Etape 8 - Banniere Home partiel

### But

Afficher les degradations apres ouverture Home sans les confondre avec une
source recovery avant Home.

### Nature

Implementation attendue si la banniere actuelle ne respecte pas le modele cible.

### Actions

- Relire `HomeDegradationNotice` et la banniere actuelle.
- Couvrir :
  - sections Home en erreur ;
  - reprise/bibliotheque indisponible ;
  - sections IPTV vides ;
  - degradations multiples.
- Conserver un format compact sur mobile.
- Eviter une surface qui ressemble a un boot bloquant.
- Brancher les actions :
  - retry Home sections ;
  - retry Library ;
  - resync Source si applicable.
- Verifier que la banniere n'apparait pas pour les erreurs source avant Home.

### Sortie attendue

Completer une table :

```text
degradation | message | action | format mobile | format desktop | test
```

### Definition de fini

- Home partiel reste dans Home.
- Les actions rechargent seulement la zone concernee.
- Les erreurs source avant Home ne passent pas par cette banniere.

## Etape 9 - Responsive, TV focus et accessibilite

### But

Verifier que les surfaces boot restent utilisables sur mobile, desktop et TV.

### Nature

Implementation corrective et tests attendus si des ecarts sont observes.

### Actions

- Verifier mobile avec reference `393x852`.
- Verifier desktop avec largeur contrainte.
- Verifier TV/clavier :
  - focus initial ;
  - ordre tab ;
  - navigation directionnelle ;
  - action principale atteignable ;
  - action secondaire atteignable.
- Verifier lisibilite a distance.
- Verifier que les textes longs ne debordent pas.
- Ajouter des tests widget de focus quand possible.

### Sortie attendue

Completer une table :

```text
surface | mobile | desktop | TV/focus | probleme | correction | test
```

### Definition de fini

- Aucun bouton critique n'est inaccessible au clavier.
- Les textes tiennent dans leurs conteneurs.
- Le focus initial est coherent sur les ecrans actionnables.

## Etape 10 - Tests widget et snapshots critiques

### But

Verrouiller le rendu des ecrans critiques avant le nettoyage legacy.

### Nature

Implementation tests attendue.

### Actions

- Ajouter ou completer les tests widget pour :
  - chargement simple ;
  - preparation catalogue ;
  - recovery source timeout ;
  - credentials invalides ;
  - catalogue vide ;
  - profil requis ;
  - source requise ;
  - selection source requise ;
  - technical failure ;
  - Home partial banner.
- Verifier les assertions critiques :
  - logo reel ;
  - texte bas ecran ;
  - absence d'action sur les ecrans non interactifs ;
  - action principale ;
  - action secondaire conditionnelle ;
  - focus initial ;
  - absence de reason code visible.
- Executer les tests cibles.

### Sortie attendue

Completer une table :

```text
test | ecran | entree BootScreenModel | assertion critique | fichier
```

### Definition de fini

- Les ecrans critiques ont un test widget.
- Les actions sont testables.
- Les etats non interactifs ne deviennent pas actionnables par regression.

## Etape 11 - Verification manuelle ciblee

### But

Verifier le rendu reel sur les formats demandes et documenter les limites.

### Nature

Validation manuelle ciblee. Implementation corrective si un probleme bloquant
est observe.

### Actions

- Lancer l'application localement si possible.
- Verifier mobile :
  - `393x852` ;
  - chargement simple ;
  - recovery ;
  - pages d'action.
- Verifier desktop :
  - largeur contrainte ;
  - pas de formulaire trop large.
- Verifier TV/clavier :
  - focus initial ;
  - navigation vers action secondaire ;
  - lisibilite.
- Documenter les validations impossibles.

### Sortie attendue

Completer une table :

```text
surface | viewport | scenario | resultat | evidence | risque restant
```

### Definition de fini

- Les formats critiques ont ete verifies ou l'impossibilite est documentee.
- Les problemes bloquants sont corriges ou reportes avec justification.
- La Phase 5 peut supprimer le legacy avec une base UI stable.

## Etape 12 - Synthese Phase 4

### But

Documenter les decisions UI et preparer le nettoyage legacy.

### Nature

Documentation uniquement, sauf mise a jour mineure de checklist.

### Actions

- Produire une synthese courte :
  - widgets crees ou adaptes ;
  - surfaces legacy remplacees ou conservees ;
  - ecrans couverts ;
  - tests ajoutes ;
  - validations manuelles ;
  - risques restants pour Phase 5, Phase 6 et Phase 7.
- Mettre a jour la checklist de definition de fini.

### Sortie attendue

Creer ou completer :

```text
docs/app_launch_refactor/phase_4_ui_boot_et_composants/DECISIONS.md
```

### Definition de fini

- La Phase 5 sait quels widgets legacy supprimer ou conserver.
- La Phase 6 sait quels textes/logs localiser ou normaliser.
- La Phase 7 sait quels scenarios UI reprendre en validation globale.

## Livrables de la phase

- `ROADMAP.md` : plan d'execution de la phase.
- `UI_COMPONENT_AUDIT.md` : composants existants et ecarts Figma.
- `BOOT_RENDERER_CONTRACT.md` : contrat `BootScreenModel -> Widget`.
- `BOOT_LOADING_SCREENS.md` : chargements simples.
- `CATALOG_LOADING_SCREEN.md` : preparation catalogue et cache.
- `BOOT_RECOVERY_PANEL.md` : recoveries actionnables.
- `BOOT_COMPONENT_VARIANTS.md` : variantes composants boot.
- `ACTION_PAGES_UI.md` : pages auth/profil/source alignees.
- `HOME_PARTIAL_BANNER.md` : banniere Home partiel.
- `RESPONSIVE_AND_FOCUS.md` : mobile, desktop, TV/focus.
- `BOOT_WIDGET_TEST_COVERAGE.md` : tests widget critiques.
- `MANUAL_UI_VALIDATION.md` : verification manuelle ciblee.
- `DECISIONS.md` : synthese finale de la phase.
- Widgets boot reutilisables.
- Renderer `BootScreenModel -> Widget`.
- Tests widget pour les ecrans critiques.

## Checklist Phase 4

- [x] Composants existants relus et ecarts Figma documentes.
- [x] Contrat `BootScreenModel -> Widget` defini.
- [ ] Renderer boot cree ou branche.
- [ ] Chargements simples implementes.
- [ ] Logo reel utilise via `MoviAssetIcon` et `AppAssets.iconAppLogoSvg`.
- [ ] Texte bas ecran conserve hors du flux logo centre.
- [ ] Chargement catalogue implemente.
- [ ] `catalog_preparing` non interactif.
- [ ] Recovery action panel implemente.
- [ ] Actions principales focusables.
- [ ] Actions secondaires conditionnelles rendues.
- [ ] Variantes composants boot ajoutees seulement si necessaire.
- [ ] Pages d'action auth/profil/source alignees sans deplacer la logique metier.
- [ ] Banniere Home partiel alignee.
- [ ] Responsive mobile `393x852` verifie.
- [ ] Desktop largeur contrainte verifiee.
- [ ] TV/focus clavier verifie ou impossibilite documentee.
- [ ] Tests widget critiques ajoutes ou mis a jour.
- [ ] Verification manuelle faite ou impossibilite documentee.
- [ ] Synthese Phase 4 produite.
