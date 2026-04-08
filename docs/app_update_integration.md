# Contrôle de version applicative

## Objectif

Bloquer l'entrée dans l'application quand la version installée n'est plus supportée par la politique distante gérée dans Supabase.

## Architecture intégrée

- `core/app_update/domain` : contrat métier de décision de compatibilité
- `core/app_update/application` : use case unique `CheckAppUpdateRequirement`
- `core/app_update/data` : récupération Edge Function + cache local court
- `core/app_update/presentation` : garde d'entrée affiché avant `MyApp`
- `supabase/functions/check-app-version` : décision serveur
- `supabase/migrations/20260408_create_app_versio
n_policies.sql` : politique stockée côté base

## Comportement

1. Le bootstrap existant initialise la configuration et les dépendances.
2. Le garde `appUpdateDecisionProvider` exécute le use case.
3. Si la réponse est `force_update`, l'app reste bloquée sur un écran dédié.
4. Si la réponse est `allowed` ou `soft_update`, l'app continue.
5. Si le réseau échoue, la dernière décision locale est réutilisée uniquement si :
   - elle concerne la même version et la même plateforme ;
   - elle est encore fraîche ;
   - ou elle est bloquante.

## Points d'attention

- En build release, l'absence d'enregistrement du use case de contrôle de version est considérée comme une erreur.
- La table de politique de version est stockée dans le schéma `private` pour éviter un accès direct depuis le client mobile.
- Les URLs de store par défaut dans la migration sont à remplacer avant déploiement.
