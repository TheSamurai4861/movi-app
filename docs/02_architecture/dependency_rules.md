# Regles de dependances

## Objectif

Ce document formalise les regles de dependances du projet `Movi`.

Il sert a :

- limiter le couplage entre couches et entre features ;
- rendre les futurs refactorings plus predictibles ;
- aider a trancher ou placer un nouveau fichier ;
- distinguer les dependances autorisees, tolerees et a eviter.

## Contexte

Ces regles sont basees sur l'etat reel du depot au 17 mars 2026.

Le projet n'est pas une clean architecture stricte. Il repose aujourd'hui sur :

- Riverpod pour une partie importante de l'etat et de la presentation ;
- GetIt pour le wiring infra et une partie des services globaux ;
- GoRouter pour la navigation et une partie des transitions d'etat ;
- des features organisees en couches, mais pas de facon parfaitement uniforme.

Le document distingue donc :

- les regles cibles a appliquer des maintenant ;
- les exceptions structurelles deja presentes ;
- les dettes a ne pas etendre.

---

## Vue d'ensemble

Grandes zones du code :

- [`core/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core)
  Socle transverse, infrastructure et domaines transverses.
- [`shared/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared)
  Types et services communs a plusieurs features de contenu.
- [`features/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features)
  Fonctionnalites produit.

Mesure brute des imports observes :

- `features -> core` : tres frequent
- `features -> shared` : frequent
- `features -> features` : frequent aussi, donc deja une vraie source de couplage
- `core -> features` : present surtout dans le wiring, le router et quelques bridges
- `shared -> features` : faible mais existant, donc deja une dette structurelle

Conclusion :

- `core` est le socle principal ;
- `shared` est un socle metier commun, pas un dossier "divers" ;
- les imports inter-features doivent etre reduits et cadres, pas banalises.

---

## Regle directrice

Quand un code doit etre reutilisable par plusieurs zones, on privilegie cet ordre :

1. `shared/domain` si le concept est metier et transverse
2. `core` si le sujet est applicatif, technique ou transverse au runtime
3. import inter-feature seulement si la reutilisation est locale, stable et clairement assumee

En pratique :

- on prefere deplacer une abstraction commune vers `shared` ou `core`
- on evite d'importer un fichier "pratique" depuis une autre feature juste pour gagner du temps

---

## Matrice de dependances

### Regle cible entre grandes zones

| Source | Peut dependre de | Commentaire |
| --- | --- | --- |
| `core` | `core`, `shared` | normal |
| `core` | `features` | seulement pour composition globale, wiring ou navigation |
| `shared` | `shared`, `core` | autorise si besoin d'infrastructure transverse |
| `shared` | `features` | a eviter ; dette existante, pas un modele |
| `features` | `core`, `shared` | normal |
| `features` | autre `feature` | seulement si la dependance est stable, intentionnelle et limitee |

### Lecture simple

- `features -> core` : normal
- `features -> shared` : normal
- `features -> features` : tolerable mais doit rester cible
- `core -> features` : reserve au runtime global
- `shared -> features` : a ne pas etendre

---

## Regles par couche interne

Les modules qui suivent une structure `application / data / domain / presentation` doivent respecter les principes suivants.

### `presentation`

Peut dependre de :

- `application`
- `domain`
- `core` presentation/utilitaires/providers transverses
- `shared` presentation/domain

Doit eviter :

- appels directs a la persistence SQLite
- logique de mapping complexe
- import direct de data sources d'une autre feature

Tolere aujourd'hui :

- import de providers ou widgets d'autres features dans des ecrans de composition
- import de pages d'autres features quand l'UI compose un parcours produit plus large

### `application`

Peut dependre de :

- `domain`
- `core`
- `shared`

Doit eviter :

- dependre de `presentation`
- contenir du code widget

### `data`

Peut dependre de :

- `domain`
- `core`
- `shared`

Peut exceptionnellement dependre d'une autre feature si :

- elle consomme un contrat ou un type stable deja expose
- la responsabilite reste clairement du cote "integration"

Doit eviter :

- importer la presentation d'une autre feature
- devenir un point d'agregation informel de plusieurs domaines sans clarification

### `domain`

Regle cible :

- `domain` ne depend pas de `presentation`
- `domain` ne depend pas de `data`
- `domain` depend surtout de ses propres entites/contrats et de `shared/domain`

Dette observee a ne pas reproduire :

- certains fichiers de `domain` importent deja des implementations ou data sources d'autres modules, surtout autour de `home`

Donc :

- ne pas ajouter de nouvelles dependances `domain -> data`
- si vous touchez une zone qui le fait deja, considerer cela comme une dette a resorber, pas comme une regle implicite

---

## Exceptions autorisees

Certaines zones ont le droit d'importer plus large car leur role est precis.

### 1. Router global

[`app_router.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_router.dart) et [`app_routes.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/router/app_routes.dart) peuvent importer :

- des pages de features ;
- des args de route ;
- des widgets transverses ;
- des gardes de navigation.

Raison :

- le graphe de navigation global est par nature un point de composition central.

### 2. DI global

[`injector.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/injector.dart) peut importer :

- les modules data des features ;
- les repositories concrets ;
- les bridges Supabase, storage, logging, config.

Raison :

- le wiring global GetIt doit assembler les implementations concretes.

### 3. Shell global

[`app_shell_page.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/shell/presentation/pages/app_shell_page.dart) peut importer directement :

- `home`
- `search`
- `library`
- `settings`

Raison :

- la coque applicative compose volontairement les onglets de premier niveau.

### 4. Bridges Riverpod / GetIt

Les fichiers sous [`core/di/providers/`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/providers) peuvent exposer des contrats de features via Riverpod.

Exemple :

- [`repository_providers.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/di/providers/repository_providers.dart)

Raison :

- ils servent de couche d'exposition transversale, pas de logique metier.

---

## Exceptions existantes mais a ne pas etendre

Ces dependances existent deja, mais ne doivent pas devenir un modele par defaut.

### `shared -> features`

Exemples observes :

- [`iptv_content_resolver_impl.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/shared/data/services/iptv_content_resolver_impl.dart) depend de types IPTV
- certains services `shared/domain` importent des types ou datasources `movie`, `tv` ou `iptv`

Regle :

- ne pas ajouter de nouveaux imports `shared -> features` sans raison forte
- si un concept devient vraiment transverse, le remonter plutot vers `shared/domain` ou `core`

### `domain -> data`

Exemples observes surtout dans `home`.

Regle :

- on n'ajoute plus de nouvelles dependances de ce type
- quand on modifie ces zones, on privilegie un passage par contrat ou service de domaine

### imports inter-features en presentation

Exemples observes :

- `home` importe des providers `movie`, `tv`, `library`, `settings`
- `library` importe `playlist`, `movie`, `tv`, `settings`
- `search` importe `movie`, `tv`, `saga`

Regle :

- acceptable pour la composition d'ecrans ou de parcours
- a eviter si la dependance porte sur une implementation profonde ou instable

---

## Regles pratiques pour ajouter un nouveau fichier

### Si le code est purement technique et transverse

Le placer dans `core`.

Exemples :

- config
- secure storage
- logging
- router
- startup
- widgets communs

### Si le code est metier et partage par plusieurs features de contenu

Le placer dans `shared`.

Exemples :

- value objects de contenu
- services TMDB transverses
- modeles UI communs a plusieurs fiches medias

### Si le code appartient a un parcours utilisateur ou a un domaine produit precis

Le placer dans la feature correspondante.

Exemples :

- pages `movie`
- providers `library`
- use cases `iptv`
- widgets `search`

### Si deux features veulent reutiliser le meme code

Se poser cette question avant tout import direct :

1. est-ce un besoin vraiment transverse et durable ?
2. si oui, faut-il monter ce code vers `shared` ou `core` ?
3. sinon, peut-on garder une dependance inter-feature locale et stable ?

---

## Ce qu'il faut eviter

- importer la `presentation` d'une feature depuis le `domain` d'une autre
- importer une data source concrete d'une autre feature depuis un nouveau service de domaine
- creer un dossier `shared` local dans une feature pour contourner `core` ou `shared`
- mettre des types metiers transverses dans `core/utils`
- utiliser `GetIt` directement dans toute nouvelle UI si un provider Riverpod clair peut exposer la dependance
- multiplier les barrels flous qui cachent des dependances inter-features massives

---

## Heuristiques de revue

Avant d'accepter une nouvelle dependance, verifier :

1. La dependance pointe-t-elle vers une abstraction ou vers une implementation concrete ?
2. Depasse-t-elle le niveau de responsabilite attendu de la couche ?
3. Rend-elle une feature dependante d'une autre juste pour reutiliser un petit morceau de code ?
4. Le code devrait-il plutot vivre dans `shared/domain`, `shared/presentation` ou `core` ?
5. Ce nouvel import rendra-t-il un futur test ou refactoring plus difficile ?

Si la reponse est "oui" a au moins deux de ces questions, il faut probablement reposer le design.

---

## Regles de travail recommandees des maintenant

- nouvelle dependance inter-feature : justification explicite
- nouveau type metier transverse : preferer `shared/domain`
- nouveau service technique transverse : preferer `core`
- nouveau point de composition global : centraliser dans router, shell ou DI, pas dans une feature metier arbitraire
- nouveau provider de presentation : preferer la feature proprietaire du flux
- nouvelle exception structurelle : la documenter ou l'eviter

---

## Points ouverts

- homogeniser progressivement les couches `application / data / domain / presentation` selon les features
- reduire les dependances `shared -> features`
- reduire les imports inter-features dans `home`, `library`, `search`, `movie` et `tv`
- documenter ensuite les flux `startup`, `data_flow` et `state_management`

## Derniere mise a jour

2026-03-17
