# Contrat d'execution Codex

Ce document est destine a etre donne a Codex au debut d'une tache. Il complete
la demande utilisateur et sert de contrat d'execution pour ce repository.

## Bloc a fournir a Codex

```text
Applique strictement c:\Users\berny\DEV\Flutter\movi\docs\codex_execution_contract.md
pour cette tache.

Obligations:
- Lire d'abord c:\Users\berny\DEV\Flutter\movi\docs\rules.md et appliquer ces regles.
- Utiliser c:\Users\berny\DEV\Flutter\movi\docs\run_logs_commands.md pour toute
  reproduction runtime ou capture de logs.
- Inspecter les fichiers impactes avant de modifier le code.
- Faire le changement necessaire dans le code, pas seulement une analyse, sauf si
  la demande est explicitement conceptuelle.
- Limiter les changements au perimetre utile. Pas de refactor large hors sujet.
- Preserver les changements existants. Ne rien revert sans demande explicite.
- Apres une modification, executer les verifications adaptees.
- Si une verification n'est pas lancee, expliquer clairement pourquoi.
- Dans la reponse finale, indiquer les fichiers modifies, les commandes executees,
  le resultat des verifications et les risques restants.
```

## Workflow obligatoire

1. Lire `docs/rules.md` avant de proposer ou d'implementer une solution.
2. Comprendre le code existant avant de modifier l'architecture, les providers,
   les dependances ou le flux de navigation.
3. Preferer une correction simple, lisible et locale.
4. Eviter l'architecture speculative, les abstractions prematurees et les
   nettoyages non demandes.
5. Preserver les conventions du projet en matiere de structure, nommage, logs,
   tests et separation des responsabilites.
6. Ne jamais cacher un blocage: l'expliquer avec la cause et la consequence.

## Regles de verification

Apres toute modification, lancer la verification la plus proche du changement,
puis elargir seulement si necessaire.

Ordre de priorite:

1. Test cible le plus proche du code modifie.
2. `flutter analyze`
3. `flutter test` complet si le changement touche une zone transverse, si les
   tests cibles sont insuffisants, ou si la demande l'exige.
4. `flutter run` ou `flutter build` seulement si le bug concerne le runtime, la
   navigation, une plateforme precise, les `dart-define` ou l'integration.

Minimum attendu selon le type de tache:

- Changement Dart/Flutter avec tests existants proches: lancer le ou les tests
  cibles puis `flutter analyze`.
- Changement Dart/Flutter sans test cible evident: lancer au minimum
  `flutter analyze`.
- Correction de bug runtime/UI/navigation: reproduire avec les commandes de
  `docs/run_logs_commands.md`, puis verifier le correctif sur le meme chemin.
- Changement de documentation seule: aucune commande Flutter obligatoire, mais
  l'indiquer explicitement.
- Changement de configuration ou CI: verifier au minimum la coherence locale
  lisible du fichier touche; lancer une commande locale si elle existe et si
  elle est pertinente.

## Format de diagnostic attendu

Quand un log est fourni, partir de ces entrees:

- commande exacte lancee
- chemin du log dans le workspace
- comportement attendu
- comportement observe
- heure approximative si le log est long

Pour les reproductions runtime, preferer les commandes documentees dans
`docs/run_logs_commands.md`.

## Regles logs et secrets

- Utiliser les logs pour diagnostiquer, pas pour noyer la reponse.
- Conserver les identifiants utiles au diagnostic quand ils sont deja masques.
- Ne jamais republier un mot de passe, un token, une cle API ou une URL signee
  sensible.
- Si un log contient des secrets, les resumer ou les masquer dans la reponse.

## Format de sortie attendu

La reponse finale doit contenir, de facon concise:

- ce qui a ete change
- les fichiers touches
- les commandes executees
- le resultat des verifications
- les risques restants, hypotheses ou points non verifies

## References du repository

- Regles de code: `docs/rules.md`
- Commandes de run et logs: `docs/run_logs_commands.md`
