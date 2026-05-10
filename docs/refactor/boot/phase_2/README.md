# Phase 2 - Sortir la decision d'entree de l'orchestrateur legacy

## Contrat d'execution

Cette phase doit etre executee en appliquant strictement :

- `docs/codex_execution_contract.md` ;
- `docs/rules.md` ;
- `docs/run_logs_commands.md` uniquement si une reproduction runtime ou une
  capture de logs devient necessaire.

La phase 2 doit extraire la decision d'entree sans reecrire tout le demarrage.
`AppLaunchOrchestrator` peut rester le point d'integration temporaire, mais il
ne doit plus porter directement la logique metier auth/profil/source une fois la
phase terminee.

## Objectif

Construire un service pur `ResolveEntryDecision` capable de transformer les
snapshots auth/profil/source en `EntryDecision`.

Le service doit permettre de repondre clairement a la question :

```text
Ou envoyer l'utilisateur maintenant ?
```

Destinations legacy a conserver :

- `auth` ;
- `welcomeUser` ;
- `welcomeSources` ;
- `chooseSource` ;
- `home`.

## Non-objectifs

Ne pas faire dans cette phase :

- modifier le contrat catalogue ;
- rendre Home non bloquant ;
- changer les ecrans de recuperation ;
- changer les routes publiques ;
- modifier les textes utilisateur ;
- supprimer `AppLaunchOrchestrator` ;
- remplacer tout le tunnel de demarrage ;
- traiter les erreurs feed, bibliotheque ou refresh IPTV.

Ces sujets appartiennent aux phases suivantes. La phase 2 doit uniquement isoler
la decision d'entree.

## Fichiers a inspecter avant modification

Avant toute modification de code, lire au minimum :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/app_startup_gate.dart`
- `lib/src/core/startup/domain/boot_contracts.dart`
- `lib/src/core/startup/domain/entry_journey_contracts.dart`
- `lib/src/core/startup/domain/tunnel_state.dart`
- `lib/src/core/startup/entry_journey_orchestrator.dart`
- `lib/src/core/startup/entry_journey_shadow_bridge.dart`
- `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
- `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`
- `lib/src/core/auth/domain/repositories/auth_repository.dart`
- `lib/src/core/profile/domain/repositories/profile_repository.dart`
- `lib/src/core/preferences/selected_profile_preferences.dart`
- `lib/src/core/preferences/selected_iptv_source_preferences.dart`
- `lib/src/core/storage/repositories/iptv_local_repository.dart`

Verifier aussi les tests existants autour de startup et entry journey :

```powershell
rg --files test | rg "startup|entry|bootstrap|launch"
```

## Emplacement recommande

Ajouter le service pur dans le domaine startup :

```text
lib/src/core/startup/domain/resolve_entry_decision.dart
```

Tests recommandes :

```text
test/core/startup/resolve_entry_decision_test.dart
```

Si le code existant montre qu'un nom deja etabli convient mieux, garder le nom
metier explicite et eviter les dossiers generiques `utils` ou `helpers`.

## Entrees du service

`ResolveEntryDecision` ne doit pas lire directement Riverpod, GetIt, storage,
reseau ou repositories. Il doit recevoir des snapshots deja lus.

Signature recommandee :

```dart
final class ResolveEntryDecision {
  const ResolveEntryDecision();

  EntryDecision call(EntryDecisionInput input);
}
```

Modele d'entree recommande :

```dart
final class EntryDecisionInput {
  const EntryDecisionInput({
    required this.isAuthenticated,
    required this.profileCount,
    required this.hasValidProfileSelection,
    required this.sourceCount,
    required this.hasValidSourceSelection,
    required this.requiresSourceSelection,
    required this.selectedProfileId,
    required this.selectedSourceId,
    required this.catalogMode,
  });

  final bool isAuthenticated;
  final int profileCount;
  final bool hasValidProfileSelection;
  final int sourceCount;
  final bool hasValidSourceSelection;
  final bool requiresSourceSelection;
  final String? selectedProfileId;
  final String? selectedSourceId;
  final CatalogMode catalogMode;
}
```

Le modele exact peut etre ajuste pour reutiliser les contrats existants
`SessionContractSnapshot`, `ProfilesContractSnapshot` et
`SourcesContractSnapshot` si cela garde le service simple et testable.

## Regles de decision

Ordre de priorite attendu :

1. Session absente ou invalide -> `RequireAuth`
2. Aucun profil exploitable -> `RequireProfile`
3. Selection profil invalide -> `RequireProfile`
4. Aucune source exploitable -> `RequireSource`
5. Plusieurs sources ou selection source invalide -> `RequireSourceSelection`
6. Profil et source resolus -> `OpenHome`

Reason codes recommandes :

| Situation | `EntryDecision` | Reason code | Destination legacy |
| --- | --- | --- | --- |
| Session absente | `RequireAuth` | `auth_required` | `auth` |
| Aucun profil | `RequireProfile` | `profile_required` | `welcomeUser` |
| Profil selectionne invalide | `RequireProfile` | `profile_selection_required` | `welcomeUser` |
| Aucune source | `RequireSource` | `source_required` | `welcomeSources` |
| Plusieurs sources sans selection valide | `RequireSourceSelection` | `source_selection_required` | `chooseSource` |
| Source selectionnee invalide | `RequireSourceSelection` | `source_selection_required` | `chooseSource` |
| Profil + source OK | `OpenHome` | `entry_ready` | `home` |

## Invariants

- Le service est pur et deterministe.
- Le service ne lance pas de navigation.
- Le service ne lit pas l'etat global.
- Le service ne logge pas lui-meme.
- Les `reasonCode` restent stables et logs-safe.
- `OpenHome` ne peut etre produit que si un profil et une source valides sont
  disponibles.
- `CatalogMode` ne doit pas encore declencher la recuperation catalogue dans
  cette phase, sauf si l'invariant existant de `OpenHome` l'exige.
- `AppLaunchOrchestrator` reste responsable de l'adaptation legacy pendant la
  phase 2.

## Adaptateur legacy attendu

`AppLaunchOrchestrator` doit utiliser `ResolveEntryDecision` pour obtenir une
decision, puis traduire cette decision vers le comportement existant.

Mapping d'adaptation attendu :

| `EntryDecision` | Comportement legacy conserve |
| --- | --- |
| `RequireAuth` | route ou etat actuel `auth` |
| `RequireProfile` | route ou etat actuel `welcomeUser` |
| `RequireSource` | route ou etat actuel `welcomeSources` |
| `RequireSourceSelection` | route ou etat actuel `chooseSource` |
| `OpenHome` | route ou etat actuel `home` |
| `TechnicalBootFailure` | chemin d'erreur technique existant |

Le but est de rendre l'orchestrateur plus mince, pas de changer ce que
l'utilisateur voit.

## Roadmap phase 2

### Etape 1 - Audit cible sans modification

Objectif : identifier ou la decision auth/profil/source est actuellement prise.

Actions :

- lire les fichiers listes dans "Fichiers a inspecter avant modification" ;
- lister les conditions qui menent vers `auth`, `welcomeUser`,
  `welcomeSources`, `chooseSource` et `home` ;
- identifier les snapshots deja disponibles dans `entry_journey_contracts.dart`
  et `entry_journey_orchestrator.dart` ;
- verifier les tests existants autour de l'entree.

Livrable :

- aucune modification de code ;
- decision sur la signature finale de `ResolveEntryDecision`.

Verification :

- aucune commande Flutter obligatoire.

### Etape 2 - Ajouter le service pur

Objectif : creer `ResolveEntryDecision` sans le brancher a l'orchestrateur.

Actions :

- creer le service pur ;
- creer ou reutiliser le modele d'entree ;
- appliquer l'ordre de decision documente ;
- retourner les types `EntryDecision` crees en phase 1 ;
- ne pas importer Flutter, Riverpod, GetIt, storage ou repositories.

Livrable :

- `lib/src/core/startup/domain/resolve_entry_decision.dart`
- aucun changement de navigation.

Verification :

- poursuivre vers les tests de l'etape 3 ;
- lancer `flutter analyze` si le service est ajoute sans tests dans la meme
  session.

### Etape 3 - Couvrir les decisions par tests unitaires

Objectif : verrouiller toutes les destinations legacy avant integration.

Actions :

- creer `test/core/startup/resolve_entry_decision_test.dart` ;
- tester session absente -> `RequireAuth` ;
- tester aucun profil -> `RequireProfile` ;
- tester selection profil invalide -> `RequireProfile` ;
- tester aucune source -> `RequireSource` ;
- tester plusieurs sources sans selection valide -> `RequireSourceSelection` ;
- tester source selectionnee invalide -> `RequireSourceSelection` ;
- tester profil + source valides -> `OpenHome`.

Verification :

```powershell
flutter test test/core/startup/resolve_entry_decision_test.dart
```

### Etape 4 - Ajouter une integration additive

Objectif : rendre le service disponible au tunnel sans changer le comportement.

Actions acceptables :

- exposer `ResolveEntryDecision` via provider simple ;
- utiliser le service dans un chemin shadow ou diagnostic ;
- comparer la destination legacy actuelle avec la nouvelle decision ;
- logger uniquement des `reasonCode` et destinations, sans identifiants bruts.

Actions interdites :

- changer les routes ;
- changer les textes utilisateur ;
- supprimer le chemin legacy ;
- brancher le catalogue ou Home readiness.

Verification :

```powershell
flutter test test/core/startup/resolve_entry_decision_test.dart
flutter analyze
```

### Etape 5 - Brancher l'orchestrateur comme adaptateur temporaire

Objectif : faire de `AppLaunchOrchestrator` un adaptateur autour de
`ResolveEntryDecision` pour la decision d'entree.

Actions :

- remplacer les conditions auth/profil/source du legacy par un appel au
  service ;
- garder les memes destinations finales ;
- conserver les logs existants utiles, en ajoutant le `reasonCode` si possible ;
- ne pas modifier les preloads Home ou catalogue ;
- ne pas changer la gestion des erreurs techniques.

Livrable :

- orchestrateur plus mince sur la partie decision d'entree ;
- comportement visible identique pour les destinations supportees.

Verification :

```powershell
flutter test test/core/startup/resolve_entry_decision_test.dart
flutter analyze
```

Si des tests existants couvrent `AppLaunchOrchestrator`, les lancer aussi.

### Etape 6 - Revue de fin de phase

Objectif : confirmer que l'extraction est assez sure pour preparer la phase 3.

Checklist :

- `ResolveEntryDecision` est pur et testable ;
- toutes les destinations legacy sont couvertes ;
- les reason codes sont stables et logs-safe ;
- `AppLaunchOrchestrator` ne porte plus directement la decision
  auth/profil/source ;
- aucun changement UI ou route publique n'a ete introduit ;
- les tests cibles passent ;
- `flutter analyze` passe.

Livrable :

- note finale avec fichiers modifies, commandes executees, resultats et risques
  restants, conformement a `docs/codex_execution_contract.md`.

## Tests attendus

Tests unitaires minimaux :

```text
test/core/startup/resolve_entry_decision_test.dart
```

Cas a couvrir :

- session absente ;
- aucun profil ;
- profil selectionne invalide ;
- aucune source ;
- plusieurs sources sans selection valide ;
- source selectionnee invalide ;
- profil + source valides.

Tests d'integration ou existants a lancer si l'orchestrateur est modifie :

```powershell
rg --files test | rg "startup|entry|bootstrap|launch"
```

Puis lancer les tests pertinents trouves.

## Criteres d'acceptation

- `ResolveEntryDecision` existe et ne depend pas de Flutter UI, Riverpod, GetIt,
  repositories, storage ou reseau.
- Les decisions retournent les types `EntryDecision` de la phase 1.
- Les destinations `auth`, `welcomeUser`, `welcomeSources`, `chooseSource` et
  `home` restent supportees.
- `AppLaunchOrchestrator` agit comme adaptateur temporaire pour la decision
  d'entree.
- Aucun comportement catalogue/Home n'est modifie dans cette phase.
- Les tests unitaires couvrent toutes les destinations legacy.
- `flutter analyze` passe apres integration.

## Risques a surveiller

- Melanger decision d'entree et preparation catalogue : la phase 2 ne doit pas
  decider de la recuperation source avancee.
- Modifier involontairement la navigation : toute destination legacy doit rester
  equivalente.
- Lire les repositories dans le service pur : les lectures doivent rester dans
  les adaptateurs.
- Deduire `home` avec un profil ou une source non valide : `OpenHome` doit
  rester strict.
- Introduire des logs avec IDs bruts : utiliser les `reasonCode` et des valeurs
  redacted.

## Definition of done

La phase 2 est terminee quand :

1. `ResolveEntryDecision` existe dans le domaine startup ;
2. toutes les destinations legacy sont couvertes par tests ;
3. `AppLaunchOrchestrator` utilise le service ou un adaptateur equivalent ;
4. le comportement visible des routes d'entree reste identique ;
5. `flutter analyze` passe ;
6. une note de revue de fin de phase documente commandes, resultats et risques.
