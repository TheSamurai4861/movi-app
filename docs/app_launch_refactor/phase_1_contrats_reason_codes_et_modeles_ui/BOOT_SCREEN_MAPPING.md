# Mapping reason code vers modele UI

## Synthese

Cette table est le contrat entre le runtime de boot et l'UI Figma.

Principes :

- les reason codes restent internes et log-safe ;
- les textes utilisateur ne reprennent jamais les reason codes ;
- les chargements simples et catalogue sont non interactifs ;
- les ecrans action/recovery ont une action principale stable ;
- `cached/stale` ouvrent Home et ne deviennent pas une recovery source ;
- Home partiel est affiche apres Home, jamais comme blocage avant Home.

## Table centrale

| etat/reason code | screen type | titre | message | action principale | action secondaire | destination | notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `technical_startup` | `simpleLoading` | - | Demarrage de Movi | - | - | - | Bootstrap technique avant `MyApp`. Non interactif. |
| `session_check` | `simpleLoading` | - | Verification de la session | - | - | - | Sous-etat UI de `AppLaunchPhase.auth`. |
| `profile_check` | `simpleLoading` | - | Preparation du profil | - | - | - | Sous-etat UI de `AppLaunchPhase.profiles`. |
| `source_check` | `simpleLoading` | - | Verification de la source | - | - | - | Couvre sources/localAccounts/sourceSelection tant qu'aucune action n'est requise. |
| `catalog_preparing` | `catalogLoading` | - | Preparation du catalogue | - | - | - | Etat non interactif visible pendant le refresh bloquant. Texte bas d'ecran. |
| `catalog_snapshot_missing` | `catalogLoading` si refresh possible, sinon `recovery` | Catalogue en preparation | Nous preparons le contenu de votre source | - si refresh en cours, sinon `resyncSource` | `chooseSource` si recovery | - ou `welcomeSources` | Signal de detection. Ne doit pas etre l'ecran final du refresh nominal. |
| `catalog_snapshot_cached` | `openingHome` | - | Ouverture de l'accueil | - | - | `home` | Snapshot exploitable. Pas de warning boot. |
| `catalog_snapshot_stale` | `openingHome` | - | Ouverture de l'accueil | - | - | `home` | Snapshot exploitable. Resync eventuelle apres Home, non bloquante. |
| `catalog_snapshot_fresh` | `openingHome` | - | Ouverture de l'accueil | - | - | `home` | Cas nominal. |
| `catalog_cached_ready` | `openingHome` | - | Ouverture de l'accueil | - | - | `home` | Alias UI pour cached/stale ouvrable. |
| `opening_home` | `openingHome` | - | Ouverture de l'accueil | - | - | `home` | Etat bref pendant preload Home/library. |
| `home_ready` | `openingHome` ou aucune UI | - | Ouverture de l'accueil | - | - | `home` | Peut ne pas etre rendu si navigation immediate. |
| `auth_required` | `actionRequired` | Connexion requise | Connectez-vous pour continuer | `login` | - | `auth` | Action stable vers la page auth. |
| `profile_required` | `actionRequired` | Creez votre profil | Ajoutez un profil pour personnaliser Movi | `createProfile` | - | `welcomeUser` | Creation profil. |
| `profile_selection_required` | `actionRequired` | Choisissez un profil | Selectionnez le profil a utiliser | `chooseProfile` | - | `welcomeUser` | Selection profil. Si la page legacy ne distingue pas encore, le mapper doit le faire. |
| `source_required` | `actionRequired` | Ajoutez une source | Connectez une source IPTV pour afficher votre catalogue | `addSource` | - | `welcomeSources` | Source absente ou aucune source exploitable. |
| `source_selection_required` | `actionRequired` | Choisissez une source | Selectionnez la source a utiliser | `chooseSource` | `addSource` si disponible | `chooseSource` | Selection source. |
| `catalog_sync_timeout` / `source_timeout` | `recovery` | La source ne repond pas | Impossible de preparer le catalogue pour le moment | `retry` | `chooseSource` | `welcomeSources` cible provisoire | Recovery source avant Home. |
| `catalog_provider_error` / `provider_error` | `recovery` | Impossible de charger la source | Le fournisseur n'a pas renvoye un catalogue exploitable | `retry` | `chooseSource` | `welcomeSources` cible provisoire | Recovery source avant Home. |
| `catalog_credentials_invalid` / `credentials_invalid` | `recovery` | Connexion a la source impossible | Verifiez les identifiants de cette source | `reconnectSource` | `chooseSource` si disponible | `welcomeSources` cible provisoire | Ne doit plus tomber sur provider error apres mapping runtime. |
| `catalog_empty` | `recovery` | Aucun contenu trouve | La source ne contient pas encore de contenus exploitables | `resyncSource` | `chooseSource` | `welcomeSources` cible provisoire | Ne pas confondre avec Home sections empty. |
| `catalog_snapshot_unavailable` | `recovery` | Catalogue indisponible | Le catalogue local ne peut pas etre lu | `retry` | `exportLogs` | - | Erreur locale/stockage, pas provider direct. |
| `boot_config_timeout` | `technicalFailure` | Demarrage interrompu | Movi n'a pas termine sa configuration a temps | `retry` | `exportLogs` | - | Erreur technique avant tunnel applicatif. |
| `boot_dependencies_timeout` | `technicalFailure` | Demarrage interrompu | Certaines dependances n'ont pas repondu a temps | `retry` | `exportLogs` | - | Technique. |
| `boot_technical_failure` / `technical_failure` | `technicalFailure` | Impossible de demarrer Movi | Une erreur technique empeche le lancement | `retry` | `exportLogs` | - | Ne pas afficher le message exception brut. |
| `home_preload_invalid_state` | `technicalFailure` | Accueil indisponible | L'accueil n'a pas pu etre prepare correctement | `retry` | `exportLogs` | - | Echec preload Home avant navigation. |
| `home_feed_failed` / `home_sections_failed` | `homePartialNotice` | Accueil partiellement charge | Certaines sections ne sont pas disponibles | `retryHomeSections` | - | `home` | Notice apres Home. |
| `library_preload_failed` / `library_failed` | `homePartialNotice` | Bibliotheque indisponible | La reprise et la bibliotheque seront rechargees separement | `retryLibrary` | - | `home` | Notice apres Home. |
| `library_preload_timeout` | `homePartialNotice` | Bibliotheque lente a charger | La bibliotheque sera rechargee en arriere-plan | `retryLibrary` | - | `home` | Notice apres Home. |
| `home_iptv_sections_empty` / `iptv_sections_empty` | `homePartialNotice` | Sections IPTV indisponibles | Les sections de la source ne sont pas encore disponibles | `retryHomeSections` | `resyncSource` | `home` | Home reste ouverte. Ce n'est pas `catalog_empty`. |
| `home_partial` / `multiple_degradations` | `homePartialNotice` | Accueil partiellement charge | Certaines donnees seront rechargees separement | `retryHomeSections` | `retryLibrary` | `home` | Actions dedupliquees selon degradations reelles. |

## Severite par famille

| famille | screen type | severity | focus initial |
| --- | --- | --- | --- |
| Chargement simple | `simpleLoading` | `info` | `none` |
| Chargement catalogue | `catalogLoading` | `info` | `none` |
| Ouverture Home | `openingHome` | `info` | `none` |
| Action requise | `actionRequired` | `warning` | `primaryAction` |
| Recovery source | `recovery` | `warning` | `primaryAction` |
| Erreur technique | `technicalFailure` | `error` | `primaryAction` |
| Home partiel | `homePartialNotice` | `warning` | `primaryAction` si action visible, sinon `none` |

## Invariants du mapping

- Chaque ligne actionnable doit avoir `primaryAction`.
- Aucun loading ne doit avoir `primaryAction`, `secondaryAction` ou focus.
- `exportLogs` ne doit jamais etre la seule action utile.
- Les textes utilisateur doivent rester courts et non techniques.
- Les destinations restent abstraites : le handler/router les applique en phase
  2.
- `catalog_snapshot_cached`, `catalog_snapshot_stale` et
  `catalog_cached_ready` ne produisent jamais `recovery`.
- `home_iptv_sections_empty` ne doit jamais etre mappe vers `catalog_empty`.

## Tests associes

| comportement | test cible |
| --- | --- |
| Tous les etats cibles produisent un `BootScreenModel`. | `boot_ui_state_mapper_test.dart`. |
| Les reason codes ne fuitent pas dans les textes. | `boot_no_reason_code_leak_test.dart`. |
| Loading non interactif sans focus. | `boot_screen_model_invariants_test.dart`. |
| Action/recovery avec action principale. | `boot_screen_model_invariants_test.dart`. |
| Cached/stale ouvrent Home. | `boot_ui_state_mapper_test.dart`. |
| Credentials invalid mappe `reconnectSource`. | `boot_ui_state_mapper_test.dart`. |
| Home partial reste apres Home. | `boot_ui_state_mapper_test.dart`. |

## Definition de fini - etape 7

- Chaque etat cible minimal est mappe.
- Aucun etat utilisateur important ne tombe sur un message generique.
- Les actions Figma ont une intention technique stable.
