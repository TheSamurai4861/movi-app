# Runbook — Settings impactant le runtime (Audio/Subtitles sync offsets)

**Runbook ID** : `RBK-108`  
**Flux** : Settings impactant le runtime (sync offsets)  
**Référence flux** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` (ligne “Settings impactant le runtime”).  
**Statut** : `draft` (R2)

---

## Symptômes

- Slider d’offset sans effet.
- Fallback “non supporté” affiché à tort.
- Offsets audio/sous-titres incohérents après relance.

## Signaux attendus (observabilité)

- `operationId` lors de `setSubtitleOffsetMs`, `setAudioOffsetMs`, `resetOffsets`.
- Logs `settings_sync` avec offsets (valeurs numériques OK), `supported=true|false`, `result`.
- Sentry : exceptions UI/state.

## Diagnostic (checklist)

1. Filtrer logs par `operationId`.
2. Vérifier si la plateforme/player déclare le support (supported flag).
3. Vérifier persistance (prefs) et relecture après relance.

## Mitigation

- Reset offsets.
- Basculer source/player si limitation technique.

## Rollback

- Se référer à la stratégie R3 (rollback opérationnel versionné).

