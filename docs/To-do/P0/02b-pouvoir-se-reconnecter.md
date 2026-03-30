# Pouvoir se reconnecter si le backend est passé en local

## Problème actuel

Quand le téléphone ou l'app bascule en mode local plutôt qu'en mode cloud, il n'existe pas de parcours clair dans les paramètres pour se reconnecter au compte utilisateur.

Conséquence : l'utilisateur peut continuer à utiliser l'app en local, mais il n'a pas de point d'entrée évident pour revenir à un état connecté quand le backend redevient disponible.

## Objectif

- Permettre à l'utilisateur de voir clairement s'il est connecté ou non au cloud
- Offrir un point d'entrée simple pour se reconnecter depuis les paramètres
- Clarifier la séparation entre état local et état cloud dans l'UI
- Éviter toute impasse fonctionnelle après un passage en mode local

## Portée

### Inclus

- UX des paramètres liée au compte cloud
- Affichage de l'état connecté / non connecté
- Point d'entrée vers le flux de reconnexion
- Positionnement du bouton `Se connecter` ou de la section `Compte`

### Exclu pour l'instant

- Refonte complète de l'authentification
- Refonte du bootstrap global
- Gestion avancée des conflits local / cloud après reconnexion

## Scénarios à couvrir

### App connectée puis bascule en mode local

- L'utilisateur a déjà utilisé un compte cloud
- Le backend devient indisponible ou la session n'est plus exploitable
- L'app reste utilisable en local
- L'utilisateur doit pouvoir comprendre qu'il est en mode local et retrouver une action de reconnexion

### App démarrée en local sans session cloud active

- Aucun compte cloud actif n'est associé à l'état courant
- Les paramètres doivent proposer un accès explicite à la connexion

### Retour du backend ou volonté de reprise cloud

- L'utilisateur veut relancer une session cloud
- Le chemin doit être direct, compréhensible, et cohérent avec le reste de l'UI

## Options UX à comparer

### Option 1

- Description :
  - créer une page `Compte`
  - lorsqu'un compte est connecté, cette page affiche les informations du compte et l'action `Se déconnecter`
  - lorsqu'aucun compte n'est connecté, cette même entrée devient le point d'entrée de reconnexion
- Avantages :
  - structure claire et évolutive
  - sépare proprement `Compte` du reste des settings
  - cohérent si d'autres infos cloud sont ajoutées plus tard
- Inconvénients :
  - demande plus de navigation
  - nécessite un état vide bien traité
- Statut :
  - non retenue pour cette itération

### Option 2

- Description :
  - afficher `Compte` uniquement lorsqu'un compte cloud est connecté
  - sinon, remplacer directement cette ligne par un bouton ou une entrée `Se connecter`
- Avantages :
  - très simple à comprendre
  - moins de friction quand l'utilisateur est offline puis veut se reconnecter
- Inconvénients :
  - la structure de la page change selon l'état
  - moins robuste si la gestion compte devient plus riche
- Statut :
  - partiellement retenue, avec adaptation

## Réflexions actuelles

- Avoir un paramètre `Compte` quand je suis connecté, avec :
  - les informations du compte
  - un bouton `Se déconnecter`
  - cette logique dans une page dédiée plutôt que directement dans `Settings`
- Ou afficher un bouton / une entrée `Se connecter` à la place de `Compte` lorsqu'aucun compte n'est associé à l'app

## Décision UX retenue

- Conserver une entrée stable dans `Settings` sous la forme `Compte cloud`
- Ne pas créer de page `Compte` dédiée pour cette itération
- Réutiliser le flux OTP existant pour la reconnexion
- Faire porter l'essentiel de l'information directement dans la section `Comptes`
- Garder une structure simple, cohérente avec l'existant, et sans nouvelle navigation si elle n'apporte rien

## États UI retenus

### État 1 - Connecté

- Une ligne `Compte cloud`
- Valeur affichée :
  - email du compte si disponible
  - sinon `Connecté`
- Action disponible :
  - ouvrir le flux lié au compte si nécessaire plus tard
  - conserver le bouton `Déconnexion`

### État 2 - Mode local

- Une ligne `Compte cloud`
- Valeur affichée :
  - `Mode local`
- Une ligne d'action supplémentaire :
  - `Se connecter`
- Objectif :
  - rendre la reconnexion visible sans masquer l'état actuel de l'app

### État 3 - Cloud indisponible

- Une ligne `Compte cloud`
- Valeur affichée :
  - `Cloud indisponible`
- Aucune action de reconnexion immédiate si le backend n'est pas joignable ou si Supabase n'est pas prêt
- Le but est d'éviter une action qui semble possible mais échoue d'emblée

## Libellés UX retenus

- Titre de ligne principal :
  - `Compte cloud`
- États :
  - `Connecté`
  - `Mode local`
  - `Cloud indisponible`
- Action secondaire :
  - `Se connecter`
- Action destructive existante conservée :
  - `Déconnexion`

## Règles d'affichage retenues

- L'entrée `Compte cloud` reste visible en permanence
- Le bouton `Déconnexion` n'est visible que lorsqu'une session cloud est active
- L'action `Se connecter` n'apparaît que lorsqu'aucune session cloud n'est active mais que le flux de reconnexion reste pertinent
- Le parcours de reconnexion depuis `Settings` doit revenir à l'écran précédent après succès, pas relancer tout l'onboarding

## Réutilisation prévue

- Réutiliser la ligne de réglage existante dans `Settings`
- Réutiliser le bouton de déconnexion existant en le rendant conditionnel
- Réutiliser l'écran OTP existant pour ne pas créer un second flux de connexion
- Réutiliser les providers déjà en place pour l'état d'authentification et la disponibilité du client Supabase

## Tâches et réflexions

- Identifier l'état actuel exposé par l'UI pour la session cloud
- Vérifier comment `Settings` décide aujourd'hui d'afficher les actions liées au compte
- Choisir un comportement UX cible unique
- Implémenter le point d'entrée de reconnexion
- Vérifier le parcours en mode local puis après retour cloud

## Checklist d'exécution

- [ ] Cartographier le parcours actuel de connexion / déconnexion / mode local
- [x] Choisir l'UX cible pour la section `Compte`
- [x] Définir les états UI à afficher selon la session cloud
- [x] Implémenter le point d'entrée de reconnexion dans les paramètres
- [x] Vérifier le parcours utilisateur après passage en mode local

## Critères de validation

- Un utilisateur en mode local peut se reconnecter sans relancer l'app
- Les paramètres indiquent clairement l'état connecté / non connecté
- Le point d'entrée de reconnexion est visible et compréhensible
- Le parcours ne crée pas d'ambiguïté entre données locales et compte cloud

## Plan d'implémentation

### Étape 1 - Cadrage UX

- Statut :
  - fait
- Décision :
  - conserver une entrée stable `Compte cloud` dans `Settings`
  - ne pas créer de page dédiée pour cette itération
  - afficher un état clair selon la session cloud
  - déclencher la reconnexion depuis une action `Se connecter`
  - revenir à `Settings` après reconnexion réussie

### Étape 2 - Intégration Settings

- Statut :
  - fait
- Réalisation :
  - ajout de l'entrée `Compte cloud` dans la section `Comptes`
  - affichage de l'état `Connecté`, `Mode local` ou `Cloud indisponible`
  - rendu conditionnel du bouton `Déconnexion`
  - regroupement de l'état cloud et de l'action de déconnexion dans la section `Comptes`

### Étape 3 - Réutilisation du flux OTP

- Statut :
  - fait
- Réalisation :
  - réutilisation de l'écran OTP existant pour la reconnexion
  - ajout de l'action `Se connecter` dans `Settings` lorsque l'app est en mode local
  - ajout d'un comportement de retour vers l'écran précédent après succès quand le flux est lancé depuis `Settings`
  - neutralisation de la redirection automatique vers l'onboarding pour ce cas précis

### Étape 4 - Validation

- Statut :
  - fait
- Réalisation :
  - ajout de tests widget pour les états `Cloud indisponible`, `Mode local` et `Connecté` dans `Settings`
  - ajout d'un test widget pour valider le retour à l'écran précédent après reconnexion via OTP lancé depuis `Settings`
  - ajout d'un test router pour valider que `/auth/otp?return_to=previous` reste accessible malgré la guard de lancement
  - correction d'un bug de cycle de vie dans `SettingsPage.dispose()` révélé par la validation automatisée
- Preuves :
  - `flutter test test/features/settings/presentation/reconnect_validation_test.dart`
  - `flutter test test/core/router/launch_redirect_guard_reconnect_test.dart`
  - `flutter analyze`

## Risques / points d'attention

- Mélanger état local et état cloud dans une UI ambiguë
- Cacher trop profondément l'action de reconnexion
- Créer une logique différente entre onboarding, auth gate et settings
- Réintroduire un comportement bloquant alors que le mode local reste voulu

## Questions ouvertes

- Faut-il enrichir plus tard `Compte cloud` en vraie sous-page si d'autres informations cloud doivent être affichées ?
- Faut-il distinguer visuellement `Cloud indisponible` et `Non connecté` avec une icône ou une couleur dédiée ?

## Notes complémentaires

- Cette to-do est liée à la réduction de dépendance à Supabase, mais traite ici uniquement l'accessibilité UX de la reconnexion
- L'objectif n'est pas de supprimer le mode local, mais d'éviter qu'il devienne une impasse utilisateur
