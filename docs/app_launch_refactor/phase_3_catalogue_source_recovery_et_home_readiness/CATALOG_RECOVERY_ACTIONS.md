# Phase 3 - Etape 8 - Actions recovery catalogue

## Objectif

Donner une sortie utilisateur utile apres un echec source sans proposer de
navigation prematuree pendant une preparation normale.

## Decision

`catalog_preparing` reste un etat non interactif. L'utilisateur ne voit pas
`Changer de source` pendant le refresh bloquant normal.

Quand la preparation echoue, `AppLaunchOrchestrator` conserve un
`StartupRecoveryPlan` dans `AppLaunchState`. `BootScreenMapper` transforme ce
plan en actions boot testables :

- action principale : l'action la plus prudente pour corriger le blocage ;
- action secondaire : `Changer de source` uniquement si elle apporte une sortie
  utile.

Le handler existant garde la destination :

```text
RecoveryAction.chooseSource -> BootActionIntent.chooseSource -> /welcome/source/select
```

## Table des actions

```text
recovery | action principale | action secondaire | condition | destination | test
catalog_sync_timeout | Reessayer | Changer de source | refresh bloquant timeout | retry launch / source select | maps catalog timeout recovery to retry and change source
catalog_provider_error | Reessayer | Changer de source | provider inaccessible ou erreur source | retry launch / source select | maps IPTV provider error to retry or choose source
catalog_credentials_invalid | Reconnecter la source | aucune | une seule source locale connue | source settings/add source | routes to credentials recovery when Xtream refresh reports invalid credentials
catalog_credentials_invalid | Reconnecter la source | Changer de source | plusieurs sources locales connues | source settings/add source / source select | offers change source after credentials recovery when another source exists
catalog_empty | Resynchroniser | Changer de source | refresh success mais aucun contenu exploitable | source resync / source select | maps IPTV empty data to resync or choose source
catalog_preparing | aucune | aucune | preparation normale en cours | aucune | maps running preload phase to catalog loading
```

## Points de raccord

- `StartupRecoveryMapper.mapLaunchFailure` connait maintenant
  `iptvCredentialsInvalid` et le mappe vers
  `catalog_credentials_invalid`.
- `AppLaunchState.recoveryPlan` transporte les actions catalogue jusqu'au
  mapper d'ecran.
- `AppLaunchOrchestrator` ajoute `chooseSource` aux credentials invalides
  seulement si plusieurs sources locales sont connues.
- `BootScreenMapper` utilise les libelles recovery source :
  - `La source ne repond pas` ;
  - `Impossible de charger la source` ;
  - `Connexion a la source impossible` ;
  - `Aucun contenu trouve`.

## Definition de fini de l'etape 8

- [x] `Changer de source` n'apparait pas pendant une attente normale non
      echouee.
- [x] L'action est disponible apres timeout, provider error et catalogue vide.
- [x] L'action est disponible apres credentials invalides seulement quand une
      autre source locale existe.
- [x] Le handler cible est testable via `BootActionPlanner`.
