# Raccordement pages auth/profil/source aux actions boot

## Decision

Les pages auth, profil et source restent proprietaires de leurs formulaires,
validations, erreurs metier et focus TV. Quand une sortie change le tunnel boot
global, la page emet une intention `BootActionIntent` via `executeBootAction`.

Le handler ne valide pas les donnees metier. Il applique uniquement la suite du
tunnel :

- relancer le boot par `/launch` quand une donnee structurante vient d'etre
  ajoutee ou confirmee ;
- envoyer vers l'ecran de chargement source quand un catalogue doit etre
  prepare ;
- ouvrir Home quand le chargement manuel a synchronise l'orchestrateur.

## Table de raccordement

| page | evenement success | evenement failure | notification orchestrateur | route suivante | test |
| --- | --- | --- | --- | --- | --- |
| `AuthPasswordPage` | `AuthStatus.authenticated` apres password sign-in | erreurs email/password/global dans `AuthPasswordController` | `executeBootAction(retry, reasonCode: auth_completed)` si `returnOnSuccess=false`; `router.pop(true)` conserve si `return_to=previous` | `/launch`, puis decision guard/orchestrateur | `test/features/auth/presentation/auth_otp_page_navigation_test.dart`; `test/features/auth/presentation/auth_password_mode_and_reset_test.dart` |
| `AuthOtpPage` | `AuthStatus.authenticated` apres verification OTP | erreurs email/code/global dans `AuthOtpController` | `executeBootAction(retry, reasonCode: auth_completed)` si `returnOnSuccess=false`; `router.pop(true)` conserve si `return_to=previous` | `/launch`, puis decision guard/orchestrateur | `test/features/auth/presentation/auth_password_mode_and_reset_test.dart` |
| `AuthForgotPasswordPage` | demande de reset acceptee ou neutralisee | erreur sender masquee par notice neutre | aucune notification boot : flow auth interne | reste sur reset ou retour auth selon action utilisateur | `test/features/auth/presentation/auth_password_mode_and_reset_test.dart` |
| `AuthUpdatePasswordPage` | mot de passe mis a jour | validation locale ou lien expire | aucune notification boot : recovery auth interne | retour manuel vers `/auth/otp` | `test/features/auth/presentation/auth_password_mode_and_reset_test.dart` |
| `WelcomeUserPage` | profil existant continue ou nouveau profil cree | validation nom/PIN ou sauvegarde profil affichee dans la page | `executeBootAction(retry, reasonCode: profile_completed/profile_created)` | `/launch`, puis destination calculee par l'orchestrateur | `test/core/router/new_user_auth_launch_flow_test.dart`; `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart` |
| `WelcomeUserPage` auth opportuniste | OTP `return_to=previous` revient avec `true` | auth annulee ou erreur auth dans page auth | pas de decision boot directe; la page reprend son action profil | reste sur `welcomeUser` puis `retry` apres profil | `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart` |
| `WelcomeSourcePage` | source ajoutee et activee | validation formulaire ou erreur controller affichee localement | `executeBootAction(resyncSource, reasonCode: source_connected)` | `/welcome/sources/loading?force_reload=1` | `test/features/welcome/presentation/welcome_source_loading_page_test.dart` |
| `WelcomeSourceSelectPage` | source selectionnee | erreur de lecture liste ou push preferences non bloquant | `executeBootAction(resyncSource, reasonCode: source_selected)` | `/welcome/sources/loading?force_reload=1` | `test/features/welcome/presentation/welcome_source_loading_page_test.dart` |
| `WelcomeSourceLoadingPage` | catalogue charge et `completeManualSourceLoadingToHome` termine | timeout/provider/erreur catalogue affichee dans la page avec retry/select source | `completeManualSourceLoadingToHome(...)`, puis `executeBootAction(openHome, reasonCode: home_ready)` | `/` | `test/features/welcome/presentation/welcome_source_loading_page_test.dart` |
| `WelcomeSourceLoadingPage` selection requise | aucune source active apres resolution | erreur locale si resolution impossible | `executeBootAction(chooseSource, reasonCode: source_selection_required)` | `/welcome/sources/select` | `test/features/welcome/presentation/welcome_source_loading_page_test.dart` |

## Focus et action principale

| page | focus/action principale | statut |
| --- | --- | --- |
| `AuthPasswordPage` | `AuthPasswordPrimaryAction` porte le sign-in password; retour TV conserve via `PopScope` et focus directionnel | conserve |
| `AuthOtpPage` | `AuthOtpPrimaryAction` alterne envoi code / verification code selon l'etape; fallback password reste secondaire | conserve |
| `WelcomeUserPage` | action principale profil continue/create utilise les focus nodes existants; recovery retry passe par `BootActionIntent.retry` | raccorde |
| `WelcomeSourcePage` | action principale connect/activate reste dans le controller source; succes passe par `BootActionIntent.resyncSource` | raccorde |
| `WelcomeSourceSelectPage` | selection de source reste metier; ajout source reste navigation locale justifiee | raccorde |
| `WelcomeSourceLoadingPage` | retry local relance le chargement; selection source et ouverture Home passent par action boot | raccorde |

## Navigations conservees

| navigation | raison |
| --- | --- |
| `return_to=previous` auth | flow de reconnect/settings : la page appelante attend un resultat local, pas une decision boot globale |
| `AuthPasswordPage` vers forgot-password | navigation auth interne |
| `AuthOtpPage` vers password fallback | navigation auth interne |
| `WelcomeSourceSelectPage` vers add source | action metier locale qui affiche le formulaire source existant |
| retours `pop`/fallback dans welcome source | navigation UI locale, pas une destination boot finale |

## Tests a conserver ou renforcer

| test | scenario | assertion critique |
| --- | --- | --- |
| `auth_otp_page_navigation_test.dart` | succes auth primaire | route vers `/launch` via action boot |
| `auth_password_mode_and_reset_test.dart` | `return_to=previous` | conserve le `pop(true)` sans relancer le boot |
| `new_user_auth_launch_flow_test.dart` | auth puis profil | le tunnel repasse par `/launch` et le guard decide la suite |
| `welcome_source_loading_page_test.dart` | chargement manuel source | Home n'est ouvert qu'apres synchronisation orchestrateur |
| futur test action source | source connectee/selectionnee | `resyncSource` pointe vers `/welcome/sources/loading?force_reload=1` |

## Limites

- `WelcomeForm` reste un composant legacy avec une navigation directe vers Home
  documentee en Phase 2 Etape 6. Il ne doit pas servir de base au nouveau
  renderer boot.
- `executeBootAction` effectue un `reset()` orchestration best-effort avant
  `/launch`. Dans les tests de route isoles, le graphe startup complet peut ne
  pas etre monte; la navigation vers `/launch` reste alors le handoff stable.
