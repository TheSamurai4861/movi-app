# Sous-phase 5.4 - Migration des composants, routes et branchements

## Objectif

Traduire le plan de phase 5 en migrations concretes visibles dans la codebase, en precisant:
- quels composants reutiliser, extraire, remplacer ou supprimer
- quelles routes garder, projeter, fusionner ou retirer
- quels branchements legacy nettoyer

Cette sous-phase ne fait pas encore le nettoyage final. Elle fixe la carte de migration a suivre.

## Principe directeur

On ne migre pas "des pages" isolees.

On migre:
1. des composants communs
2. des surfaces branchees sur le nouvel etat
3. des routes projetees par le routeur cible
4. des branchements legacy qui deviennent sans objet

## Inventaire des briques existantes les plus directement concernees

### Routing et orchestration

- [app_router.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_router.dart)
- [launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart)
- [app_routes.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_routes.dart)
- [app_route_paths.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_route_paths.dart)
- [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart)
- [bootstrap_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/providers/bootstrap_providers.dart)

### Etat et providers legacy

- [app_state_provider.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/state/app_state_provider.dart)
- [app_state_controller.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/state/app_state_controller.dart)
- [welcome_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/providers/welcome_providers.dart)

### Composants UI existants

- [overlay_splash.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/overlay_splash.dart)
- [launch_error_panel.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/launch_error_panel.dart)
- [movi_primary_button.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_primary_button.dart)
- [movi_subpage_back_title_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_subpage_back_title_header.dart)
- [welcome_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_header.dart)
- [welcome_form.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_form.dart)
- [iptv_source_selection_list.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart)

### Surfaces tunnel existantes

- [welcome_user_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_user_page.dart)
- [auth_otp_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/auth/presentation/auth_otp_page.dart)
- [welcome_source_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_page.dart)
- [welcome_source_select_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart)
- [welcome_source_loading_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart)

### Preferences et selections

- [selected_profile_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_profile_preferences.dart)
- [selected_iptv_source_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_iptv_source_preferences.dart)

## Plan de migration des composants

## 1. Composants a conserver comme base

Ces briques sont de bonnes bases pour la refonte, meme si elles devront parfois etre recomposees.

| Existant | Decision | Usage cible |
| --- | --- | --- |
| [overlay_splash.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/overlay_splash.dart) | conserver / refactorer | base de `Preparation systeme` |
| [movi_primary_button.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_primary_button.dart) | conserver | CTA primaire commun |
| [movi_subpage_back_title_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_subpage_back_title_header.dart) | conserver / simplifier | header tunnel sur certaines surfaces |
| [welcome_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_header.dart) | conserver comme matiere | futur `TunnelHeroBlock` |
| [welcome_form.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_form.dart) | conserver comme matiere | futur `TunnelFormShell` |
| [iptv_source_selection_list.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart) | conserver comme base | liste / galerie source du hub cible |

## 2. Composants a extraire ou refactorer

Ces briques doivent devenir des composants communs du tunnel.

| Cible | Sources probables | Decision |
| --- | --- | --- |
| `TunnelPageShell` | pages `welcome/*`, [movi_subpage_back_title_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_subpage_back_title_header.dart) | extraction |
| `TunnelHeroBlock` | [welcome_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_header.dart) | extraction |
| `TunnelFormShell` | [welcome_form.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_form.dart) | extraction |
| `TunnelInlineMessage` | [launch_error_panel.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/launch_error_panel.dart) + messages actuels des pages | extraction |
| `TunnelRecoveryBanner` | erreurs source / startup actuelles | extraction |
| `ProfileChoiceGallery` | UI `welcome_user_page` / surfaces profil | extraction |
| `SourcePickerHub` | [welcome_source_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_page.dart) + [welcome_source_select_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart) + [iptv_source_selection_list.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart) | fusion + extraction |

## 3. Composants a laisser disparaitre avec les surfaces legacy

Ces briques ne doivent pas survivre si elles restent seulement des wrappers du tunnel historique.

| Existant | Condition de suppression |
| --- | --- |
| variantes hybrides propres a `welcome_user_page` | suppression apres migration `F2-F4` |
| composition ad hoc du flux source dans [welcome_source_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_page.dart) | suppression apres `G1-G3` |
| structure de [launch_error_panel.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/launch_error_panel.dart) si elle reste purement startup historique | suppression apres `F1` et migration recovery |

## Plan de migration des routes

## 1. Routes a conserver comme compatibilite temporaire

| Route | Statut cible | Role pendant migration |
| --- | --- | --- |
| `/launch` | compat temporaire | point d'entree historique tant que `routing_v2` n'est pas complet |
| `/welcome/user` | compat temporaire | redirige ou rend la surface profil/auth selon phase de migration |
| `/auth/otp` | compat temporaire puis projection cible | surface auth tant que la projection cible n'est pas totalement stabilisee |
| `/welcome/sources` | compat temporaire | point de bascule vers hub source |
| `/welcome/sources/select` | compat temporaire courte | ne doit vivre que pendant la fusion du hub source |
| `/welcome/sources/loading` | compat temporaire courte | remplacee ensuite par la projection `Chargement medias` |

## 2. Routes a projeter via le nouveau routeur

La cible n'est pas de multiplier les nouveaux chemins publics, mais de faire projeter les surfaces par `TunnelSurface`.

Projection recommandee:
- `Preparation systeme`
- `Auth`
- `Creation profil`
- `Choix profil`
- `Choix / ajout source`
- `Chargement medias`

Decision:
- tant que possible, conserver les URLs publiques utiles
- changer la logique de projection plus que les chemins eux-memes

## 3. Routes a fusionner ou supprimer

| Existant | Decision | Condition |
| --- | --- | --- |
| `/welcome/sources` + `/welcome/sources/select` | fusion | apres `G1` |
| `/welcome/sources/loading` comme page historique | remplacement | apres `H1-H2` |
| `redirect /welcome -> /welcome/user` historique | simplification | apres `routing_v2` stabilise |

## Plan de migration des branchements legacy

## A. Routing et redirections

| Branchement | Decision | Precondition de suppression |
| --- | --- | --- |
| [launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart) logique metier | reduire progressivement | `D2` stabilise, telemetry OK |
| [app_routes.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_routes.dart) redirects legacy tunnel | simplifier | surfaces migrees + projection routeur stable |
| [app_router.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_router.dart) construction actuelle dependante du registre legacy | refactorer | `TunnelSurface` et nouveau coeur actifs |

## B. Orchestration et providers

| Branchement | Decision | Precondition de suppression |
| --- | --- | --- |
| [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart) comme moteur unique legacy | transformer en bridge puis retirer du chemin critique | `B4` stabilise |
| [bootstrap_providers.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/providers/bootstrap_providers.dart) branchement direct sur le legacy | refactorer | `state_model_v2` actif |
| [app_state_controller.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/state/app_state_controller.dart) implication centrale dans le tunnel | reduire | coeur tunnel branche sur nouvel orchestrateur |
| [app_state_provider.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/state/app_state_provider.dart) exposition de prefs / selections au coeur du tunnel | decoupler | `H3` |

## C. Preferences et selections

| Branchement | Decision | Precondition de suppression |
| --- | --- | --- |
| [selected_profile_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_profile_preferences.dart) comme quasi source de verite | releguer en persistence | derive profil stable |
| [selected_iptv_source_preferences.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/preferences/selected_iptv_source_preferences.dart) comme quasi source de verite | releguer en persistence | derive source stable |

## D. Pages tunnel legacy

| Surface legacy | Decision | Precondition de suppression |
| --- | --- | --- |
| [welcome_user_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_user_page.dart) | decomposer puis supprimer | `F2-F4` stabilises |
| [auth_otp_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/auth/presentation/auth_otp_page.dart) | conserver puis rebrancher | suppression seulement quand surface auth cible stable |
| [welcome_source_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_page.dart) | fusionner | `G1-G3` stabilises |
| [welcome_source_select_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart) | supprimer apres fusion | `G1` stabilise |
| [welcome_source_loading_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart) | remplacer | `H1-H2` stabilises |

## Ordre recommande de migration visible

1. extraire les composants communs
2. brancher le coeur et la projection routeur
3. migrer `Preparation systeme`
4. migrer `Auth`
5. migrer `Creation profil` puis `Choix profil`
6. fusionner et migrer le hub source
7. migrer `Chargement medias`
8. retirer les pages et branchements legacy devenus orphelins

## Preconditions de suppression legacy

Une suppression legacy ne doit etre autorisee que si:

1. la surface cible equivalente existe
2. la telemetry de transition est active
3. le rollback de la bascule precedente est connu
4. aucun consumer legacy critique ne depend encore du fichier supprime
5. le comportement mobile et TV a ete verifie sur la surface cible

## Zones de nettoyage a faire le plus tard possible

Les elements suivants doivent etre nettoyes tard:
- [launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart)
- logique metier restante de [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart)
- wrappers historiques des pages `welcome/*`
- usage metier des preferences de selection

## Zones a migrer le plus tot possible

Les elements suivants gagnent a migrer tot:
- telemetry du tunnel
- modele `TunnelState`
- bridge de compatibilite
- derive `TunnelSurface`
- composants UI communs

## Verdict

La sous-phase `5.4` est suffisamment stable si l'on retient ces points:
- les migrations de composants sont mappees
- les migrations de routes sont bornees
- les branchements legacy critiques sont identifies
- chaque suppression legacy a des preconditions explicites

La suite logique est la sous-phase `5.5`, pour definir la `definition of done`, les attentes de test et les criteres de revue par lot.
