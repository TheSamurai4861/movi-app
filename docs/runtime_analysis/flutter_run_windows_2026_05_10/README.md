# Analyse runtime Flutter Windows - 2026-05-10

## Source

- Fichier analyse : `output/flutter-run-windows.log`
- Plateforme : Windows
- Session terminee par `Application finished`
- Aucun `result=failure` applicatif detecte dans le run analyse

## Synthese

L'application demarre et atteint Home correctement. Le refactor boot/catalogue
semble fonctionner : le tunnel d'entree resout la session, le profil, la source
IPTV, prepare le catalogue et navigue vers Home.

Le probleme principal n'est pas un crash, mais le cout runtime du chemin de
demarrage quand le snapshot catalogue local est absent. Home arrive apres
environ 10,8 secondes, principalement a cause d'un refresh IPTV bloquant.

## Signaux principaux

### Demarrage

- Bootstrap systeme reussi en `1747ms`.
- Session authentifiee.
- 2 profils locaux detectes.
- 2 sources IPTV locales detectees.
- Source selectionnee restauree.
- Destination finale : `home`.

### Catalogue IPTV

Sequence observee :

1. `catalog_snapshot_missing`
2. refresh Xtream bloquant
3. `refresh_xtream result=success movies=40918 series=12859`
4. `catalog_snapshot_cached`
5. Home ouverte avec `catalogMode=cached`

Le chemin est correct fonctionnellement, mais couteux :

- `catalog_minimal_ready` a `9860ms`
- `entry_journey_completed` a `10768ms`

### Home

- `preload_home result=ready code=home_ready`
- `preload_library result=ready code=home_ready`
- 58 sections IPTV presentes dans Home.
- Pas de `HomePartial` pendant ce run.

### Recherche

La recherche explicite fonctionne :

- saisie progressive de `harry potter`
- `submitQuery`
- `search success query="harry potter" movies=10 shows=2 people=1 sagas=1`
- ajout a l'historique OK.

### Detail film

Navigation vers un detail film OK, mais enrichissement couteux :

- `movie_detail fetch id=671 ... bundle=2738ms`
- cache miss initial sur le detail complet.
- sauvegarde du detail ensuite.

### Images et Home hero

Le log montre une forte activite image :

- `image_load_attempt_total` : 797
- `image_load_cache_success_total` : 791
- plusieurs hydrations Home hero entre environ 337ms et 1760ms.

Ce n'est pas une erreur, mais c'est une zone probable de cout UI/performance.

### Bruit Flutter Windows

Le log contient environ 5300 lignes :

```text
[ERROR:flutter/shell/platform/windows/task_runner_window.cc(...)] Failed to post message to main thread.
```

Aucun crash applicatif n'est associe dans la fin du run. Ce bruit semble venir
du runner/moteur Windows, probablement pendant des changements d'etat fenetre ou
la fermeture. Il rend toutefois les logs difficiles a exploiter.

## Direction de developpement conseillee

### Priorite 1 - Stabiliser le demarrage catalogue

Objectif : eviter qu'un snapshot absent impose un blocage Home de pres de 10s
sans feedback clair.

Actions recommandees :

- verifier pourquoi le snapshot local etait absent alors que 2 sources locales
  existent ;
- garantir la persistance du snapshot apres refresh ;
- ajouter un etat UI explicite de preparation source quand un refresh bloquant
  est necessaire ;
- mesurer le second run apres refresh pour confirmer que `catalog_snapshot_cached`
  evite le cout de demarrage ;
- garder la recuperation source separee de Home partiel.

### Priorite 2 - Rendre les logs exploitables

Objectif : pouvoir lire rapidement les erreurs utiles.

Actions recommandees :

- reduire ou flagger les logs `home_hero_debug` hors diagnostic cible ;
- reduire les logs `image_pipeline` repetitifs ou les agreger ;
- garder `SearchFocus` et `SearchCtrl` derriere un flag debug dedie ;
- isoler les erreurs Flutter Windows pour savoir si elles arrivent seulement a
  la fermeture, au resize ou pendant l'usage.

### Priorite 3 - Optimiser Home et les images

Objectif : limiter le travail immediat apres ouverture Home.

Actions recommandees :

- limiter le nombre de chargements image simultanes dans les listes Home ;
- verifier les rebuilds du Home hero pendant carousel/navigation ;
- profiler le cout des hydrations hero cache-miss ;
- conserver la strategie de cache, mais eviter les rafales de chargements non
  visibles.

### Priorite 4 - Clarifier Windows : TV ou desktop

Le run indique `screenType=tv` sur Windows.

Question produit a trancher :

- Windows sert-il de cible TV/test telecommande ?
- ou Windows doit-il offrir une experience desktop distincte ?

Si Windows doit etre desktop, il faut corriger le resolver avant de continuer le
polish UI. Si Windows est volontairement assimile TV, il faut documenter ce
choix et continuer a tester les flows clavier/telecommande.

## Prochaine tranche proposee

Nom de chantier conseille :

```text
Stabilisation runtime Home/boot
```

Definition de fini :

- un run avec snapshot deja present ouvre Home sans refresh bloquant ;
- un run avec snapshot absent affiche un etat source clair ;
- les logs de run permettent de lire les signaux startup, catalogue, Home et
  recherche sans etre noyes ;
- la classification Windows TV/desktop est explicite et testee.
