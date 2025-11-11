# Règles d’intervention (Assistant ↔ Projet Flutter)

## 0) Interdits & limites (haute priorité)

* **NE JAMAIS** lancer un serveur web, ni proposer de le faire.
* **PAS de tests** (unitaires/e2e/golden) **sans demande explicite**.

## 1) Toujours CLEAN Architecture (non négociable)

* **Couches**
* **Dépendances** : uniquement vers le bas (pas de fuite de `data` dans `domain`).
* **Contrats** : interfaces `Repository` dans `domain`, implémentations dans `data`.
* **DTO/Mapper** dédiés, **jamais** de JSON dans `domain`.
* **Gestion d’erreurs** typée (p.ex. `Failure`/`Result`), mapping des exceptions réseau/parse.
* **DI** obligatoire (client HTTP, config, repos) ; pas d’instances globales cachées.
* **Null-safety** stricte, immutabilité par défaut, valeurs par défaut sûres.

## 2) Qualité & style (livrables)

* Code **formaté** (`dart format`), lints respectés (ex. `flutter_lints`).
* **Logs sobres** (niveau `debug/info/error`), jamais de payloads sensibles en clair.
* **Pas de commentaires bruyants** ; seulement ce qui documente l’intention (ou `///` doc).
* **Nommer clairement** : `Dto`, `Model`, `UseCase`, `Repository`, `DataSource`, `Mapper`, `State`.

## 3) Sécurité & réseau

* **Timeouts/retry** paramétrables ; pas de retry infini.
* **Parsing** en un seul endroit (Data layer), **types stables** en sortie.

## 4) Performance & DX

* **Pas de préchargement d’images massif** ; caches dimensionnés.
* **Pagination/streaming** au besoin ; pas de listes infinies en mémoire.
* **Mesure** avant optimisation (compteurs simples/logs).
