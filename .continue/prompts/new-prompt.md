---
name: Patch
description: New prompt
invokable: true
---

Objectif : produire un **patch (diff unifié)** pour la feature **validée**.

Contraintes :
- Clean Architecture stricte
- Null-safety stricte
- Pas d’appel réseau dans la UI
- **Chemins réels uniquement**
- Inclure **1–2 tests unitaires** pertinents

Donner :
- fichiers créés / modifiés / supprimés
- le diff unifié
- un court message de commit
