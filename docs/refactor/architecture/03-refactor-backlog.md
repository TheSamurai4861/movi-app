# Backlog de refactor — Movi
## Version 2 — pilotage par décisions, dépendances et livrables

## 1. Objet du document

Ce document transforme l’audit en backlog réellement pilotable.

Son but n’est pas de lister “tout ce qu’on pourrait améliorer”.
Son but est de répondre à trois questions :

1. quels chantiers doivent commencer en premier ;
2. quels chantiers dépendent d’autres analyses avant d’être lancés ;
3. quels livrables doivent exister pour réduire le risque du refactor.

Cette V2 remplace la première version trop proche d’une liste de travaux.

---

## 2. Règle générale de pilotage

Le projet ne doit pas être refactoré :
- page par page ;
- dossier par dossier ;
- ou au feeling.

Il doit être refactoré selon cette logique :

### Étape A — Comprendre les nœuds
On documente les systèmes qui propagent la complexité.

### Étape B — Fixer les règles
On décide de la structure cible avant de déplacer beaucoup de code.

### Étape C — Réduire les centres de gravité
On simplifie les sous-systèmes les plus transverses.

### Étape D — Nettoyer le reste
On ne traite les dettes secondaires qu’après stabilisation des bases.

---

## 3. Types d’items du backlog

Chaque item appartient à l’un de ces types :

### 3.1 Discovery
But : comprendre un système avant de le modifier.

### 3.2 Decision
But : fixer une règle d’architecture ou une cible.

### 3.3 Refactor
But : modifier effectivement la structure ou le code.

### 3.4 Cleanup
But : supprimer le bruit, le legacy ou les redondances locales.

---

## 4. Statuts utilisés

- **À lancer** : suffisamment clair pour commencer
- **En attente de discovery** : ne pas lancer avant analyse dédiée
- **En attente de décision** : dépend d’une règle cible non encore fixée
- **Secondaire** : utile mais non prioritaire
- **À vérifier** : soupçon de dette ou legacy, sans preuve suffisante
- **Hors séquence** : ne pas lancer maintenant

---

## 5. Vue d’ensemble des chantiers

## Niveau 1 — Chantiers de cadrage immédiat
Ce sont les chantiers sans lesquels les autres refactors seront risqués :
1. cartographie du startup réel
2. cartographie DI / Riverpod / GetIt / état global
3. cartographie library sync
4. cartographie cycle de vie IPTV
5. définition des règles `core / features / shared`

## Niveau 2 — Chantiers de transformation structurante
Ils doivent suivre juste après le cadrage :
6. simplification du startup
7. stratégie DI cible
8. refonte conceptuelle de `library`
9. recentrage d’IPTV
10. découpage conceptuel de `settings`
11. stabilisation de `shared`

## Niveau 3 — Rationalisation secondaire
À faire après stabilisation des centres de gravité :
12. réduction des invalidations / événements diffus
13. clarification de `profile`
14. rationalisation de `search`
15. revue de la famille `movie/tv/person/saga`
16. shell/router après stabilisation d’entrée

## Niveau 4 — Nettoyage
17. i18n legacy
18. `core/widgets`
19. petits modèles/args proches
20. legacy résiduel

---

## 6. Backlog détaillé

# A. Discovery — à lancer immédiatement

## A1 — Documenter le startup réel
**Type** : Discovery  
**Statut** : À lancer  
**Priorité** : Critique  
**Impact attendu** : Très élevé

### Pourquoi cet item existe
Le startup est aujourd’hui un nœud de propagation majeur.
Le snapshot montre qu’il gère :
- enregistrement config ;
- initialisation dépendances ;
- bridge `AppStateController` Riverpod → GetIt ;
- sanity check Supabase ;
- logging ;
- setup et cycle de vie du `XtreamSyncService`. :contentReference[oaicite:6]{index=6}

### Livrable attendu
Un document dédié qui décrit :
- l’ordre exact du boot ;
- ce qui est critique ;
- ce qui peut être différé ;
- les side effects ;
- les dépendances inter-systèmes.

### Définition de terminé
On peut expliquer le démarrage en une séquence simple de 10 à 20 étapes maximum.

---

## A2 — Documenter la topologie DI / Riverpod / GetIt / AppState
**Type** : Discovery  
**Statut** : À lancer  
**Priorité** : Critique  
**Impact attendu** : Très élevé

### Pourquoi cet item existe
Le projet utilise à la fois Riverpod et GetIt, avec un bridge explicite pour compatibilité legacy autour de `AppStateController`. :contentReference[oaicite:7]{index=7}

On voit aussi des modules métiers injecter encore `sl<AppStateController>()`, par exemple dans l’enregistrement de services movie/home. :contentReference[oaicite:8]{index=8} :contentReference[oaicite:9]{index=9}

### Livrable attendu
Un document qui classe les dépendances en 3 catégories :
- Riverpod-first
- GetIt legacy
- zone mixte / ambiguë

### Définition de terminé
On sait précisément :
- où `sl<T>()` reste structurant ;
- où Riverpod est déjà la vraie entrée ;
- quelles zones peuvent migrer en premier.

---

## A3 — Documenter le flux complet de `library` sync
**Type** : Discovery  
**Statut** : À lancer  
**Priorité** : Critique  
**Impact attendu** : Très élevé

### Pourquoi cet item existe
`library` est bien plus qu’une UI de favoris.
Le snapshot montre :
- sync cursor store ;
- sync preferences ;
- services de sync multiples ;
- repositories locaux/distants ;
- providers remote ;
- bootstrap UI de sync. :contentReference[oaicite:10]{index=10} :contentReference[oaicite:11]{index=11}

### Livrable attendu
Un schéma bout en bout :
- déclenchement
- push local
- pull cloud
- fusion
- persistance
- invalidation/refetch UI

### Définition de terminé
Les flux “favoris / historique / playlists / progression” sont lisibles sur une seule page.

---

## A4 — Documenter le cycle de vie d’une source IPTV
**Type** : Discovery  
**Statut** : À lancer  
**Priorité** : Critique  
**Impact attendu** : Très élevé

### Pourquoi cet item existe
Le moteur IPTV est distribué entre :
- `features/iptv`
- `core/storage`
- sécurité/credentials
- `settings`
- startup. :contentReference[oaicite:12]{index=12} :contentReference[oaicite:13]{index=13}

En plus, les routes montrent que l’administration IPTV passe aujourd’hui par `settings/iptv/...`. :contentReference[oaicite:14]{index=14}

### Livrable attendu
Une carte claire du flux :
source ajoutée → validée → stockée → rafraîchie → sélectionnée → consommée par home/player/details.

### Définition de terminé
On peut suivre une source IPTV sans changer de “modèle mental” toutes les 2 étapes.

---

## A5 — Définir les règles d’appartenance `core / features / shared`
**Type** : Decision  
**Statut** : À lancer  
**Priorité** : Critique  
**Impact attendu** : Très élevé

### Pourquoi cet item existe
Le snapshot montre un `core` très large, et un `shared` qui héberge aussi des services très structurants comme TMDB, enrichissement, lookup, résolveurs, etc. :contentReference[oaicite:15]{index=15}

### Livrable attendu
Une convention d’architecture courte et ferme :
- ce qui va dans `core`
- ce qui va dans `features`
- ce qui peut vivre dans `shared`
- ce qui ne doit plus aller dans `shared`

### Définition de terminé
Deux personnes différentes prendraient les mêmes décisions de placement sur la majorité des nouveaux fichiers.

---

# B. Decision — à enchaîner juste après

## B1 — Décider de la cible DI officielle
**Type** : Decision  
**Statut** : En attente de discovery  
**Dépend de** : A2  
**Priorité** : Critique

### Objectif
Fixer noir sur blanc la cible :
- Riverpod = centre de gravité
- GetIt = transition contrôlée
- bridge `AppStateController` = temporaire puis retiré

### Pourquoi cet item est critique
Sans décision explicite, chaque nouveau morceau de code risque de prolonger la coexistence ambiguë actuelle.

### Livrable attendu
Un document court “DI target state”.

---

## B2 — Décider du modèle de startup cible
**Type** : Decision  
**Statut** : En attente de discovery  
**Dépend de** : A1, A2  
**Priorité** : Critique

### Objectif
Décider comment découper le lancement en :
- boot critique
- boot applicatif
- tâches différées

### Livrable attendu
Une vue cible simple du startup, avant tout gros refactor.

---

## B3 — Décider du périmètre réel de `library`
**Type** : Decision  
**Statut** : En attente de discovery  
**Dépend de** : A3  
**Priorité** : Critique

### Objectif
Définir si `playlist`, `favorites`, `history`, `progress`, `sync` restent des sous-domaines séparés ou doivent être réencapsulés sous une façade unique.

### Livrable attendu
Un contrat de sous-système pour la bibliothèque.

---

## B4 — Décider du périmètre réel de `settings`
**Type** : Decision  
**Statut** : En attente de discovery  
**Dépend de** : A4, A5  
**Priorité** : Élevée

### Objectif
Séparer conceptuellement :
- réglages utilisateur
- administration IPTV

### Pourquoi cet item compte
Les routes montrent déjà que `settings` porte des fonctions critiques d’administration IPTV. :contentReference[oaicite:16]{index=16}

### Livrable attendu
Une décision d’architecture, même si les fichiers ne bougent pas encore.

---

## B5 — Décider de la place cible des services `shared`
**Type** : Decision  
**Statut** : En attente de discovery  
**Dépend de** : A5  
**Priorité** : Élevée

### Objectif
Classer les services `shared` en :
- vraiment partagés
- à rapatrier dans une feature
- à reclasser en infra/core

---

# C. Refactor — à lancer après cadrage

## C1 — Simplifier le startup
**Type** : Refactor  
**Statut** : En attente de décision  
**Dépend de** : B1, B2  
**Priorité** : Critique

### Objectif
Réduire le nombre de responsabilités dans le lancement, sans casser les parcours critiques.

### Résultat attendu
Un startup qui compose, au lieu d’orchestrer trop de logique applicative.

---

## C2 — Réduire progressivement le bridge GetIt / Riverpod
**Type** : Refactor  
**Statut** : En attente de décision  
**Dépend de** : B1  
**Priorité** : Critique

### Objectif
Faire reculer les usages structurants de `sl<T>()` là où Riverpod doit déjà être la façade principale.

### Résultat attendu
Moins de zones mixtes et moins de dépendances “legacy-first”.

---

## C3 — Recomposer `library` comme sous-système cohérent
**Type** : Refactor  
**Statut** : En attente de décision  
**Dépend de** : B3  
**Priorité** : Critique

### Objectif
Rendre lisibles les frontières entre :
- sync
- persistance locale
- providers UI
- favorites/history/playlists/progress

### Résultat attendu
Une architecture `library` compréhensible sans devoir naviguer entre trop de couches.

---

## C4 — Recentrer le moteur IPTV
**Type** : Refactor  
**Statut** : En attente de décision  
**Dépend de** : A4, A5, B4  
**Priorité** : Élevée

### Objectif
Réduire la dispersion entre :
- feature IPTV
- settings IPTV
- storage IPTV
- startup sync
- credentials/security

### Résultat attendu
Un flux IPTV plus localisé et plus explicable.

---

## C5 — Reclasser conceptuellement `settings`
**Type** : Refactor  
**Statut** : En attente de décision  
**Dépend de** : B4  
**Priorité** : Élevée

### Objectif
Faire apparaître clairement la séparation entre :
- settings utilisateur
- admin IPTV

### Résultat attendu
Moins de confusion produit/architecture.

---

## C6 — Stabiliser `shared`
**Type** : Refactor  
**Statut** : En attente de décision  
**Dépend de** : B5  
**Priorité** : Élevée

### Objectif
Diminuer le caractère “zone de transit” de `shared`.

### Résultat attendu
Un `shared` plus petit, plus stable, plus justifiable.

---

# D. Rationalisation — après stabilisation structurelle

## D1 — Réduire les invalidations et événements diffus
**Type** : Refactor  
**Statut** : Secondaire  
**Dépend de** : A2, A3, C3  
**Priorité** : Moyenne à élevée

### Pourquoi
Le projet possède un `AppEventBus` avec des événements globaux comme `iptvSynced` et `librarySynced`, donc ce sujet devra être rationalisé, mais plutôt après clarification des gros sous-systèmes. :contentReference[oaicite:17]{index=17}

---

## D2 — Clarifier `profile` comme pivot transverse
**Type** : Refactor  
**Statut** : Secondaire  
**Priorité** : Moyenne à élevée

### Pourquoi
`profile` semble branché à auth, IPTV, parental, préférences et état courant, donc il mérite une clarification, mais pas avant startup / DI / library / IPTV. :contentReference[oaicite:18]{index=18}

---

## D3 — Rationaliser `search`
**Type** : Refactor  
**Statut** : Secondaire  
**Priorité** : Moyenne

### Pourquoi
`search` a plusieurs args/routes proches, mais sa dette paraît plus locale que structurelle. Les routes `/search_results`, `/provider_results`, `/provider_all_results`, `/genre_results`, `/genre_all_results` montrent une spécialisation qui peut probablement être allégée plus tard. :contentReference[oaicite:19]{index=19}

---

## D4 — Réévaluer `movie / tv / person / saga` comme famille commune
**Type** : Refactor  
**Statut** : Secondaire  
**Priorité** : Moyenne

### Pourquoi
Ces blocs ressemblent davantage à une famille de détails contenus qu’à quatre premiers chantiers indépendants.

---

## D5 — Revoir shell/router après stabilisation de l’entrée
**Type** : Refactor  
**Statut** : En attente  
**Dépend de** : C1  
**Priorité** : Moyenne

### Pourquoi
Le routeur reflète l’état actuel de l’app, notamment avec `launch`, `welcome/*`, `bootstrap`, `settings/iptv/*`, `library`, `player`, etc. Il vaut mieux le rationaliser après clarification du lancement. :contentReference[oaicite:20]{index=20}

---

# E. Cleanup — à faire en dernier

## E1 — Vérifier les artefacts i18n suspects
**Type** : Cleanup  
**Statut** : À vérifier  
**Priorité** : Faible à moyenne

### Cibles probables
- `app_fr_MM.arb`
- `app_localizations_bu.dart` :contentReference[oaicite:21]{index=21}

---

## E2 — Reclasser `core/widgets`
**Type** : Cleanup  
**Statut** : Secondaire  
**Priorité** : Faible à moyenne

### Pourquoi
C’est un bon sujet de dette UI structurelle, mais pas un centre de propagation majeur.

---

## E3 — Fusionner certains args/modèles proches
**Type** : Cleanup  
**Statut** : Secondaire  
**Priorité** : Faible à moyenne

### Pourquoi
Utile pour réduire le bruit, notamment côté search/navigation.

---

## E4 — Marquer le legacy résiduel
**Type** : Cleanup  
**Statut** : Secondaire  
**Priorité** : Faible à moyenne

### Objectif
Faire passer les fichiers suspects dans l’un des états :
- actif
- deprecated
- supprimé

---

## 7. Vue séquencée réelle

## Séquence 1 — Comprendre
- A1 Startup réel
- A2 Topologie DI / état global
- A3 Flux library sync
- A4 Cycle de vie IPTV
- A5 Règles `core / features / shared`

## Séquence 2 — Décider
- B1 DI cible
- B2 Startup cible
- B3 Périmètre `library`
- B4 Périmètre `settings`
- B5 Place cible de `shared`

## Séquence 3 — Transformer
- C1 Simplifier startup
- C2 Réduire le bridge GetIt / Riverpod
- C3 Recomposer `library`
- C4 Recentrer IPTV
- C5 Reclasser `settings`
- C6 Stabiliser `shared`

## Séquence 4 — Rationaliser
- D1 Invalidations / événements
- D2 Profile
- D3 Search
- D4 Famille détails contenus
- D5 Shell/router

## Séquence 5 — Nettoyer
- E1 i18n legacy
- E2 core/widgets
- E3 args proches
- E4 legacy résiduel

---

## 8. Chantiers à ne pas lancer maintenant

## Hors séquence
- refactor complet de `movie`
- refactor complet de `tv`
- grand redesign UI
- déplacement massif de fichiers sans règles cibles
- suppression brutale de GetIt
- refonte shell/router avant clarification du startup
- nettoyage “cosmétique” généralisé

### Pourquoi
Ces travaux donneraient l’impression d’avancer, tout en laissant intacts les nœuds qui propagent vraiment la complexité.

---

## 9. Définition de succès de ce backlog

Ce backlog aura servi s’il permet :
- de savoir quoi lancer maintenant ;
- de savoir quoi ne pas lancer trop tôt ;
- de savoir quels documents doivent exister avant les refactors ;
- de réduire les refactors opportunistes.

Le succès n’est donc pas :
“faire le plus d’items possible”.

Le succès est :
“diminuer le nombre de nœuds qui compliquent tout le reste”.

---

## 10. Conclusion

Cette seconde lecture du backlog conduit à une idée simple :

Le projet ne manque pas d’actions possibles.  
Il manque surtout d’un **ordre de décision**.

Le bon ordre est :
1. comprendre les nœuds critiques ;
2. fixer les règles cibles ;
3. refactorer les centres de gravité ;
4. seulement ensuite nettoyer les dettes secondaires.

Autrement dit :
le vrai progrès ne consistera pas à modifier beaucoup de fichiers,
mais à rendre le projet **plus simple à gouverner architecturalement**.