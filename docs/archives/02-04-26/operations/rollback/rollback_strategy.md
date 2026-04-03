# Stratégie de rollback — Movi (R3)

**Document** : `OPS-RBK-STRAT-001`  
**Statut** : `draft` (R3)  
**Références** : `docs/rules_nasa.md` §20.1 (release + rollback), §23 (procédures), §25 (preuves), §27 (gate rollback), `docs/quality/validation_evidence_index.md` (`PH0-BL-GAP-014`).

---

## 1) Objet

Définir une stratégie de rollback **opérationnelle** et **versionnée** pour Movi, compatible avec les contraintes réelles des stores et de la distribution (Android Play, Windows, iOS).

Cette stratégie distingue :
- **Rollback** : revenir à une version antérieure *fonctionnelle* (N-1) quand la version N provoque un incident.
- **Hotfix** : publier rapidement une version N+1 correctrice quand un rollback est impossible/insuffisant.

---

## 2) Déclencheurs (quand rollback ?)

Rollback recommandé (exemples) :
- crash rate en forte hausse post-release,
- régression bloquante sur flux critique (startup, auth, playback, sync),
- incident sécurité (C1) nécessitant retrait immédiat.

Hotfix recommandé (exemples) :
- plateformes où la réversion est limitée (iOS),
- correction ciblée plus sûre qu’un retour en arrière,
- nécessité de versionCode monotone (Android Play) empêchant “revenir en arrière” de façon stricte.

---

## 3) Prérequis (avant d’en avoir besoin)

- Avoir identifié la “version N-1” (voir §5).
- Disposer des accès opératoires (Play Console / App Store / distribution Windows).
- Connaître les procédures par plateforme (RBK-201..203).
- Disposer d’une preuve minimale de monitoring (Sentry) et de logs corrélables (R2).

---

## 4) Rôles & responsabilités (RACI minimal)

- **Incident commander** : décide rollback/hotfix, arbitre.
- **Release manager** : exécute les actions store/distribution.
- **Dev owner** : confirme la cause racine probable et le correctif.
- **QA** : valide post-rollback (checklist).

---

## 5) Lien minimal release ↔ rollback (identifier N et N-1)

Constat phase 0 : pas de tags Git et pas de `CHANGELOG.md` racine (voir `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/12_constat_release_rollback_7_3.md`).

**Mécanismes minimaux retenus en R3** (sans dépendre de R4) :

- **Identité release “app”** : `pubspec.yaml` (`version: x.y.z+build`) et `SENTRY_RELEASE` (ex `movi@x.y.z+build`).
- **Android (Play)** : `versionCode` (monotone) + `versionName`.
- **Windows** : numéro de version + hash/artefact distribution (zip/installer).
- **iOS** : `CFBundleVersion`/`CFBundleShortVersionString` (déduits du build), et notes de version.

**Règle** : la version N-1 est la dernière version “stable” (crash rate OK, pas d’incident C1/C2), identifiée par la console store ou par les artefacts de build conservés.

---

## 6) Validation post-rollback (checklist minimale)

- lancement app OK,
- auth OK (si applicable),
- playback OK (source vidéo),
- sync/library OK (si applicable),
- absence de crash spike sur 15–30 min.

---

## 7) Runbooks de rollback par plateforme

- Android (Play Console) : `docs/operations/rollback/RBK-201_android_playstore_rollback.md`
- Windows : `docs/operations/rollback/RBK-202_windows_rollback.md`
- iOS : `docs/operations/rollback/RBK-203_ios_rollback.md`

---

## 8) Preuves (R3)

R3 exige au minimum un **rehearsal** (simulation opératoire) Android, archivé en artefact daté, et lié à l’index de preuves.

