# Definition de BootScreenModel

## Decision

`BootScreenModel` est un contrat de presentation. Il projette les etats runtime
du boot vers les ecrans Figma sans remplacer les contrats domaine.

Emplacement cible :

```text
lib/src/core/startup/presentation
```

Raison :

- le modele contient des textes utilisateur et des choix d'affichage ;
- il ne doit pas polluer `core/startup/domain`, qui reste pur et sans UI ;
- il peut consommer `AppLaunchState`, `EntryDecision`, `HomeReadiness`,
  `RecoveryAction`, `StartupRecoveryReasonCodes` et `BootstrapDestination`
  sans les dupliquer.

Le mapper cible peut vivre dans :

```text
lib/src/core/startup/presentation/boot_screen_model.dart
lib/src/core/startup/presentation/boot_screen_mapper.dart
```

## Types minimaux

### `BootScreenType`

| valeur | role | interaction |
| --- | --- | --- |
| `simpleLoading` | Chargement non interactif : startup technique, session, profil, source. | Aucune. |
| `catalogLoading` | Preparation catalogue avec texte bas d'ecran. | Aucune. |
| `actionRequired` | L'utilisateur doit completer une etape : auth, profil, source. | Action principale obligatoire. |
| `recovery` | Erreur source/catalogue recuperable avant Home. | Action principale obligatoire. |
| `openingHome` | Snapshot exploitable, preload Home/library, navigation imminente. | Aucune. |
| `homePartialNotice` | Home ouverte avec degradation non bloquante. | Action optionnelle selon degradation. |
| `technicalFailure` | Erreur technique boot/startup. | Action principale obligatoire, export logs optionnel. |

### `BootActionIntent`

| valeur | source actuelle | role |
| --- | --- | --- |
| `retry` | `RecoveryAction.retry` | Relancer l'operation boot ou recovery. |
| `login` | `RecoveryAction.login` | Aller vers auth. |
| `createProfile` | `RecoveryAction.createProfile` | Demander creation profil. |
| `chooseProfile` | `RecoveryAction.chooseProfile` | Demander selection profil. |
| `addSource` | `RecoveryAction.addSource` | Demander ajout source IPTV. |
| `chooseSource` | `RecoveryAction.chooseSource` | Demander selection source. |
| `reconnectSource` | `RecoveryAction.reconnectSource` | Demander reconnexion credentials/source. |
| `resyncSource` | `RecoveryAction.resyncSource` | Relancer sync catalogue source. |
| `openHome` | `RecoveryAction.openHomeCached` ou destination `home` | Continuer vers Home quand autorise. |
| `retryHomeSections` | `RecoveryAction.retryHomeSections` | Relancer les sections Home degradees. |
| `retryLibrary` | `RecoveryAction.retryLibrary` | Relancer la bibliotheque/reprise. |
| `exportLogs` | `RecoveryAction.exportLogs` | Action diagnostic secondaire. |

Les actions restent des intentions. Elles ne portent pas de callback Flutter.
L'execution appartient a un handler de phase 2.

### `BootFocusTarget`

| valeur | usage |
| --- | --- |
| `none` | Ecran non interactif. |
| `primaryAction` | Focus initial sur l'action principale. |
| `secondaryAction` | Rare, seulement si l'action secondaire est le point d'entree voulu. |

## Table des champs

| champ | type | obligatoire | source | usage UI | test |
| --- | --- | --- | --- | --- | --- |
| `screenType` | `BootScreenType` | Oui | Mapper depuis phase, reason code, destination ou readiness. | Choisit le widget Figma : loading, recovery, action, notice Home. | Chaque etat cible produit le bon type. |
| `title` | `String?` ou cle l10n | Non pour loading simple, oui pour action/recovery/notice. | Mapper UI, pas domaine. | Titre utilisateur. Jamais un reason code. | Aucun titre ne contient `_` ou code interne. |
| `message` | `String` ou cle l10n | Oui | Mapper UI. | Texte principal, y compris texte bas d'ecran pour loading. | Aucun message generique type `Erreur inconnue`. |
| `secondaryMessage` | `String?` ou cle l10n | Non | Mapper UI. | Sous-message court pour recovery/catalogue. | Optionnel et non technique. |
| `primaryAction` | `BootActionIntent?` | Obligatoire si `isInteractive=true`, sinon null. | `RecoveryAction`, destination ou decision entry. | Bouton principal et handler technique. | Les ecrans actionnables ont une action principale. |
| `primaryActionLabel` | `String?` ou cle l10n | Obligatoire si `primaryAction != null`. | Mapper UI. | Libelle bouton principal. | Le libelle ne fuit pas de code interne. |
| `secondaryAction` | `BootActionIntent?` | Non | `RecoveryAction` secondaire ou diagnostic. | Bouton secondaire. | `exportLogs` n'est jamais seule action utile. |
| `secondaryActionLabel` | `String?` ou cle l10n | Obligatoire si `secondaryAction != null`. | Mapper UI. | Libelle bouton secondaire. | Le libelle correspond a l'intention. |
| `destination` | `BootstrapDestination?` ou route cible abstraite | Non | `EntryDecision`, `AppLaunchState.destination`, router mapping. | Permet au handler/router de savoir ou aller. | Les destinations action requise sont stables. |
| `reasonCode` | `String` | Oui | `StartupRecoveryReasonCodes`, `EntryDecisionReasonCodes` harmonise, phase derivee. | Logs, telemetry, tests. Jamais affiche. | Le reason code est present et log-safe. |
| `isInteractive` | `bool` | Oui | Derive de `primaryAction` / `secondaryAction`. | Active focus, boutons et semantics. | Loading non interactif n'a aucune action focusable. |
| `initialFocus` | `BootFocusTarget` | Oui | Derive de `screenType` et actions. | Focus TV/clavier initial. | Action principale focusable si interactive. |
| `severity` | `BootScreenSeverity` | Oui | Mapper depuis famille : info, warning, error. | Style visuel recovery/notice. | Recovery technique/source ne partage pas le style nominal. |
| `showLogo` | `bool` | Oui | Mapper UI. | Logo boot asset reel. | Loading boot affiche le logo attendu. |
| `showProgress` | `bool` | Oui | Mapper UI. | Spinner/progress si retenu. | Les ecrans non interactifs peuvent afficher un progress. |
| `metadata` | `Map<String, Object?>` log-safe | Non | Mapper runtime. | Debug/test uniquement, pas UI directe. | Aucun secret/sourceId brut. |

## Regles d'invariants

- `reasonCode` est obligatoire et log-safe.
- `reasonCode` ne doit jamais etre affiche comme `title`, `message` ou label.
- `isInteractive=false` implique `primaryAction == null`,
  `secondaryAction == null` et `initialFocus == none`.
- `isInteractive=true` implique `primaryAction != null` et
  `initialFocus == primaryAction`, sauf exception documentee.
- `secondaryAction == exportLogs` implique une action principale utile.
- `screenType.simpleLoading`, `catalogLoading` et `openingHome` sont non
  interactifs.
- `screenType.actionRequired`, `recovery` et `technicalFailure` sont
  interactifs.
- `homePartialNotice` peut etre interactif ou non selon l'action disponible,
  mais ne bloque jamais Home.

## Correspondance avec les ecrans Figma

| screen type | composant cible | notes |
| --- | --- | --- |
| `simpleLoading` | `BootLoadingScreen` | Logo centre, texte court bas d'ecran. |
| `catalogLoading` | `BootLoadingScreen` variante catalogue | Texte bas d'ecran, pas d'action. |
| `openingHome` | `BootLoadingScreen` | Etat bref, pas de warning cache/stale. |
| `actionRequired` | Pages action boot ou wrappers Figma | Auth/profil/source, action principale focusable. |
| `recovery` | `BootRecoveryScreen` | Source timeout/provider/credentials/catalogue vide. |
| `technicalFailure` | `BootRecoveryScreen` technique | Retry + export logs possible. |
| `homePartialNotice` | Notice/banniere Home partiel | Apres Home, compacte, non bloquante. |

## Pseudo-structure cible

```dart
enum BootScreenType {
  simpleLoading,
  catalogLoading,
  actionRequired,
  recovery,
  openingHome,
  homePartialNotice,
  technicalFailure,
}

enum BootActionIntent {
  retry,
  login,
  createProfile,
  chooseProfile,
  addSource,
  chooseSource,
  reconnectSource,
  resyncSource,
  openHome,
  retryHomeSections,
  retryLibrary,
  exportLogs,
}

enum BootFocusTarget { none, primaryAction, secondaryAction }

enum BootScreenSeverity { info, warning, error }

final class BootScreenModel {
  const BootScreenModel({
    required this.screenType,
    required this.message,
    required this.reasonCode,
    required this.isInteractive,
    required this.initialFocus,
    required this.severity,
    required this.showLogo,
    required this.showProgress,
    this.title,
    this.secondaryMessage,
    this.primaryAction,
    this.primaryActionLabel,
    this.secondaryAction,
    this.secondaryActionLabel,
    this.destination,
    this.metadata = const <String, Object?>{},
  });

  final BootScreenType screenType;
  final String? title;
  final String message;
  final String? secondaryMessage;
  final BootActionIntent? primaryAction;
  final String? primaryActionLabel;
  final BootActionIntent? secondaryAction;
  final String? secondaryActionLabel;
  final BootstrapDestination? destination;
  final String reasonCode;
  final bool isInteractive;
  final BootFocusTarget initialFocus;
  final BootScreenSeverity severity;
  final bool showLogo;
  final bool showProgress;
  final Map<String, Object?> metadata;
}
```

## Tests attendus

| test | objectif |
| --- | --- |
| `boot_screen_model_invariants_test.dart` | Verifier non-interactif sans actions, interactif avec action principale, export logs jamais seul. |
| `boot_ui_state_mapper_test.dart` | Verifier que les contrats runtime produisent un model stable. |
| `boot_no_reason_code_leak_test.dart` | Verifier que title/message/labels ne contiennent pas de reason code brut. |
| `boot_focus_contract_test.dart` | Verifier `initialFocus` selon interaction. |

## Definition de fini - etape 6

- Le modele UI est assez stable pour implementer les ecrans Figma.
- Les actions sont des intentions techniques, pas des callbacks ad hoc.
- Les reason codes restent log-safe et non affiches.
