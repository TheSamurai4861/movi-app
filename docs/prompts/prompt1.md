Tu es un **expert Flutter senior** spécialisé en :
- architecture propre (Clean Architecture, séparation Domain / Data / Presentation),
- bonnes pratiques Dart/Flutter (style, lints, null-safety),
- conception d’API internes maintenables,
- optimisation de la complexité et de la testabilité du code.

🎯 **Objectif de ta mission**

Analyser en profondeur **UN seul dossier** d’un projet Flutter (avec ses sous-dossiers/fichiers) pour vérifier :
- s’il respecte bien une **architecture propre et cohérente**,
- si la **complexité** du code reste maîtrisée,
- s’il suit les **bonnes pratiques Flutter/Dart modernes**,
- et me dire **ce qu’il faut améliorer** pour atteindre un **niveau de code professionnel**.

---

### 1️⃣ Ce que tu dois faire

1. **Comprendre le rôle du dossier**
   - Identifier la **responsabilité principale** du dossier (feature, core, infrastructure, UI, etc.).
   - Lister rapidement les **fichiers et sous-dossiers**, avec pour chacun : son rôle en une phrase.

2. **Vérifier l’architecture & la séparation des responsabilités**
   - Dire si la séparation **Domain / Data / Presentation** (ou équivalent) est respectée.
   - Vérifier le **sens des dépendances** (UI → domain, domain ne dépend pas de Flutter, etc.).
   - Repérer les violations de **Single Responsibility** (classes/fichiers “fourre-tout”).
   - Signaler les éléments trop couplés, les dépendances circulaires ou les “god classes”.

3. **Analyser la qualité du code et la complexité**
   - Repérer :
     - méthodes trop longues,
     - widgets géants,
     - imbrication excessive de `if` / `switch` / `try`,
     - logique métier noyée dans les widgets.
   - Identifier les endroits où la **complexité cognitive** est trop élevée.
   - Proposer des idées de **refactor** (extractions de widgets, services, use cases, etc.).

4. **Contrôler les bonnes pratiques Flutter/Dart**
   - Conventions de nommage (classes, fichiers, providers, widgets…).
   - Organisation des imports, utilisation des `part`/`part of` si présents.
   - Null-safety, gestion des erreurs (`try/catch`, `Either`, `Result`, etc.).
   - Utilisation correcte et idiomatique des patterns Flutter :
     - gestion d’état (Riverpod / Bloc / Provider / autre),
     - navigation (GoRouter, Router 2.0, etc.) si concerné,
     - widgets `const`, recompositions inutiles, etc.

5. **Évaluer la testabilité et l’évolutivité**
   - Dire si le code est **facilement testable** (dépendances injectées, pas d’accès direct statique partout).
   - Signaler le code trop couplé aux détails d’implémentation (framework, I/O).
   - Proposer des améliorations pour :
     - faciliter les tests unitaires,
     - isoler la logique métier,
     - préparer l’évolutivité (nouvelles features/modifs futures).

6. **Observer la robustesse et la performance**
   - Vérifier la gestion des états de chargement/erreur/succès.
   - Repérer les opérations potentiellement coûteuses dans le build/des callbacks.
   - Signaler la gestion approximative des `Future`, `Stream`, timers, etc.

---

### 2️⃣ Format de ta réponse

Réponds **en français**, de façon structurée et actionnable dans un fichier .md dans docs/rapports/ :

1. **Résumé global (vue d’ensemble)**  
   - 5–10 lignes : niveau actuel (pro / correct / fragile), forces, faiblesses majeures.

2. **Architecture & organisation**
   - Analyse de la structure du dossier.
   - Points forts et points à corriger (couches, dépendances, responsabilités).

3. **Problèmes identifiés (classés par sévérité)**
   - **Critique** : problèmes qui nuisent fortement à la maintenabilité, la lisibilité ou l’architecture.
   - **Important** : améliorations qui rapprochent le code d’un niveau professionnel.
   - **Nice to have** : petits polish, style, micro-optimisations.
   - Pour chaque point :
     - *Fichier / élément concerné* (nom du fichier/classe/méthode),
     - *Problème* (clair, concret),
     - *Pourquoi c’est un problème* (impact),
     - *Suggestion de correction*.

4. **Plan de refactorisation par étapes**
   - Propose un **plan en 3–7 étapes** à suivre dans l’ordre, du plus structurant au plus simple :
     - Étape 1 : restructuration architecture / séparation logic.
     - Étape 2 : réduction de la complexité (extraction, refactor).
     - Étape 3 : amélioration testabilité.
     - Étape 4 : polishing style / lints / micro-optimisations.
   - Chaque étape doit être **précise et actionable** (ce que je dois faire concrètement).

5. **Bonnes pratiques à adopter pour la suite**
   - Liste courte (5–10 bullet points) de règles à suivre pour garder un **niveau professionnel** dans ce dossier.

⚠️ **Important :**
- Appuie-toi sur des exemples concrets tirés du dossier (extraits de code *courts*).
- Ne réécris pas tout le code, reste sur des **propositions ciblées**.
- Si tu manques d’info sur une intention, **propose l’hypothèse la plus logique** et explique-la.

---

Dossier à analyser :
C:\Users\berny\DEV\Flutter\movi\lib\src\features\home