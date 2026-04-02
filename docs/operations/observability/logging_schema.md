# Observabilité — schéma de logs corrélables (minimum) — R2

**Document** : `OPS-OBS-LOG-001`  
**Statut** : `draft` (R2)  
**Références** : `docs/rules_nasa.md` §14 (observabilité), §13 (confidentialité), §25 (preuves).

---

## 1) Objectif

Définir un **minimum** de logs structurés et **corrélables** pour diagnostiquer les flux critiques, sans exposer de secrets/PII.

Le code existant fournit déjà :
- timestamp ISO (`ConsoleLogger` / `FileLogger`) ;
- `level` ;
- `category` ;
- sanitization (`MessageSanitizer`).

R2 ajoute une convention de champs et une corrélation par `operationId`.

---

## 2) Champs minimum requis (contrat)

Chaque événement important d’un flux critique doit pouvoir être agrégé par :

- `operationId` : identifiant de corrélation (une “opération” = un flux utilisateur ou système)
- `feature` : ex `startup`, `auth`, `player`, `settings`, `sync`, `parental`
- `action` : ex `restoreSession`, `play`, `resolveVariants`, `setSubtitleOffset`
- `result` : `success|fail|cancel|fallback`

Champs additionnels recommandés (si disponibles, non sensibles) :

- `durationMs` (latence)
- `errorCategory` (ex `network`, `storage`, `sdk`, `unknown`)
- `variants` (compteur)
- `supported=true|false` (capabilité)

---

## 3) Format de sérialisation (simple, robuste)

R2 retient un format `key=value` en texte (compatible console/fichier) :

```text
operationId=op_... feature=player action=play result=success durationMs=123 variants=2 message="..."
```

Règles :
- ne pas mettre de JSON complet en priorité (éviter changements lourds) ;
- `message="..."` optionnel si le texte libre est utile ;
- toute donnée sensible/PII est interdite (voir §4).

---

## 4) Confidentialité (interdits)

Conformément à `docs/rules_nasa.md` §13 :
- aucun token / secret / cookie / API key ;
- pas de PII en clair (email, identifiant brut, etc.) ;
- ne pas logger des payloads complets.

Le sanitizer existant doit rester une barrière, mais **ne remplace pas** la discipline de non-log.

---

## 5) Corrélation : `operationId`

Principe :
- `operationId` est généré au début d’un flux (ex : startup, play, sync) ;
- il est propagé via un **contexte** (scope) ;
- les loggers l’ajoutent automatiquement aux lignes émises pendant le scope.

Preuve attendue (R2) :
- un extrait de logs montrant plusieurs lignes partageant le même `operationId`.

