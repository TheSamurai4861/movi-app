# Incident App Update - 2026-04-08

## Resume

Le demarrage principal de l'application fonctionne correctement sur Windows en mode debug, mais l'entree dans l'app est bloquee juste apres le bootstrap par la verification distante `AppUpdate`.

Le symptome visible dans `run.txt` est une boucle de tentatives sur la fonction Supabase `check-app-version`, avec une erreur HTTP 500 :

```text
FunctionException(status: 500, details: {error: policy_lookup_failed, reasonCode: policy_lookup_failed})
```

La cause racine confirmee par les logs Edge Function est :

```text
PGRST106: The schema must be one of the following: public, graphql_public
```

## Symptome observes

- Le build Flutter Windows aboutit.
- Le bootstrap applicatif se termine avec `startup_ready`.
- La base locale SQLite s'ouvre correctement.
- Supabase est initialise correctement et une session utilisateur est presente.
- L'application reste ensuite bloquee pendant la phase `AppUpdate`.
- Riverpod relance automatiquement le provider en echec, ce qui provoque plusieurs appels successifs a la meme fonction Edge.

## Verifications deja faites

Les verifications SQL ont confirme que :

- le schema `private` existe ;
- la table `private.app_version_policies` existe ;
- sa structure est correcte ;
- l'index unique `(app_id, environment, platform)` existe ;
- les donnees `prod/android`, `prod/ios` et `prod/windows` existent ;
- il n'y a pas de doublons ;
- `service_role` a bien le droit `SELECT` sur `private.app_version_policies`.

Ces points montrent que le probleme ne vient ni d'une table absente, ni d'une contrainte casssee, ni d'un simple manque de `SELECT`.

## Cause racine

La fonction Edge interroge la table avec :

```ts
supabase
  .schema('private')
  .from('app_version_policies')
```

Dans ce contexte, `supabase-js` passe par la Data API / PostgREST. Or le projet Supabase n'expose actuellement que les schemas :

- `public`
- `graphql_public`

Le schema `private` n'est donc pas accessible via `.schema('private')`, meme depuis la fonction Edge, ce qui produit l'erreur `PGRST106`.

Autrement dit :

- la table existe ;
- les droits SQL sont maintenant presque bons ;
- mais la voie d'acces choisie par la fonction n'est pas autorisee par la configuration API du projet.

## Facteurs secondaires

### 1. Environnement demande par l'application

Sur Windows en mode debug, l'application envoie probablement :

- `appId = movi`
- `environment = dev`
- `platform = windows`

La table contient actuellement une policy `prod/windows`, pas `dev/windows`.

Ce point n'explique pas le `500` actuel, car avec la version recente de la fonction, l'absence de policy desktop devrait retourner `allowed`.

En revanche, cela reste un point de configuration a garder en tete pour les tests debug.

### 2. Blocage total du lancement

Le garde de demarrage traite l'erreur `AppUpdate` comme une erreur de lancement, ce qui empeche l'app de continuer meme si le bootstrap principal est sain.

Cela rend une panne backend non critique beaucoup plus visible et bloquante qu'elle ne devrait l'etre.

## Pourquoi le grant n'a pas suffi

Le droit suivant a bien ete ajoute :

```sql
grant select on table private.app_version_policies to service_role;
```

Mais l'erreur ne venait plus d'un refus SQL classique. La requete etait rejetee avant cela par PostgREST, car le schema `private` n'est pas dans la liste des schemas exposes par l'API.

## Correctifs possibles

## Option 1 - Fix rapide

Exposer le schema `private` dans la configuration API Supabase, puis conserver :

```sql
grant usage on schema private to service_role;
grant select on table private.app_version_policies to service_role;
```

Avantage :

- correction rapide ;
- peu de changements de code.

Inconvenient :

- le schema `private` devient accessible via la Data API du projet ;
- cela va a l'encontre de l'intention initiale de garder cette table dans un schema non expose.

## Option 2 - Fix propre recommande

Conserver `private.app_version_policies` dans un schema prive, mais ne plus y acceder avec `.schema('private')` depuis `supabase-js`.

Approches possibles :

- creer une fonction SQL / RPC dans `public` ou `api` qui lit `private.app_version_policies` ;
- ou utiliser une connexion Postgres directe cote Edge Function.

Avantage :

- respecte l'intention de securite du schema `private` ;
- evite de dependre des schemas exposes par PostgREST.

Inconvenient :

- demande un petit refactoring de la fonction Edge.

## Correctif applicatif recommande en plus

Independamment du backend, il est recommande de rendre `AppUpdate` non bloquant en cas d'erreur serveur non fatale.

Exemples :

- autoriser l'entree dans l'app sur erreur `5xx` sans decision cachee ;
- limiter ou desactiver le retry automatique pour ce provider ;
- afficher un warning ou logger l'incident sans bloquer tout le lancement.

## Etat actuel

Etat au 2026-04-08 :

- le bootstrap principal est sain ;
- la fonction `check-app-version` est joignable ;
- la requete vers `private.app_version_policies` echoue avec `PGRST106` ;
- le lancement reste bloque par le garde `AppUpdate`.

## Prochaines actions recommandees

1. Choisir entre le fix rapide (exposer `private`) et le fix propre (RPC ou acces direct Postgres).
2. Redeplyer la fonction `check-app-version` apres correction.
3. Rejouer un `flutter run -d windows`.
4. Verifier que `AppUpdate` retourne `allowed`, `soft_update` ou `force_update`, mais plus `policy_lookup_failed`.
5. Durcir le client pour qu'une panne backend d'App Update ne bloque pas tout le lancement.
