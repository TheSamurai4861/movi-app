# Perf Android - Hotspots et Backlog Priorisé

## Source d'observation initiale

- Logs runtime Android observés pendant usage réel (bootstrap, home, player, sync IPTV).
- Instrumentation existante exploitée:
  - `[Launch]`, `[Preload]`, `[HomeLoad]`, `[IptvSync]`
  - `[PerfDiag]`
  - `[HomeHeroDebug]`
  - `[Network] SLOW REQUEST`

## Baseline initiale (seed)

Points notables visibles dans les logs réels:

- `HomeLoad reason=preload` observé autour de `170-300ms` (quand pas de course concurrente).
- `HomeLoad reason=iptvSynced` observé jusqu'à `~700ms`.
- `home_hero_hydrate` (`PerfDiag`) observé jusqu'à `~2.7s` sur certains IDs.
- Requêtes IPTV `player_api.php` parfois > `4s` avec `SLOW REQUEST`.

Conclusion baseline seed:
- Le bootstrap peut être impacté par des rafraîchissements concurrents.
- Le coût hero metadata est variable et parfois élevé.
- Le réseau IPTV est un facteur dominant de latence perçue.

## Hotspots classés

### P0 - Réseau IPTV lent/variable

- Symptôme: `SLOW REQUEST` + latence élevée sur `player_api.php`.
- Impact: bootstrap perçu lent, disponibilité sections retardée.
- Risque: élevé sur UX démarrage.

### P0 - Concurrence refresh Home (bootstrap vs événements)

- Symptôme: `profileChange`/`iptvSynced` pouvant interférer avec preload.
- Impact: transitions bootstrap fragiles et variabilité d'affichage.
- Risque: élevé (état transitoire visible, retries).

### P1 - Hydratation Hero coûteuse

- Symptôme: `home_hero_hydrate` jusqu'à plusieurs secondes.
- Impact: jank potentiel et ressenti lent sur Home.
- Risque: moyen à élevé selon device/réseau.

### P1 - Travail UI concurrent pendant sync

- Symptôme: home rebuild + sync + hero prep simultanés.
- Impact: frame pacing instable sur navigation initiale.
- Risque: moyen.

## Backlog d'optimisation priorisé

| Priority | Hypothèse | Changement minimal | Gain attendu | Risque |
|---|---|---|---|---|
| P0 | Réduire latence perçue IPTV | Timeout/Retry policy plus fine + phase progress UX explicite | -20% à -35% sur temps perçu bootstrap | Moyen |
| P0 | Réduire courses Home | Gate strict des triggers événementiels pendant preload + debounce | Stabilisation bootstrap, moins d'échecs transitoires | Faible |
| P1 | Réduire coût Hero hydrate | Cache-first agressif + limite enrichissement initial | -15% à -30% sur jank Home | Moyen |
| P1 | Éviter surcharge au retour Home | Décaler tâches non critiques après first frame | Meilleur frame pacing (P95) | Faible |
| P1 | Réduire variance réseau | Backoff + circuit court snapshot frais | Moins de spikes > 4s | Moyen |

## Quick wins recommandés (1-3)

1. Gating + debounce des refresh non critiques pendant `preloadCompleteHome`.
2. Limiter hydratation hero complète au visible et décaler le préfetch non critique.
3. Ajouter compteur simple des `SLOW REQUEST` par scénario pour tri rapide des régressions.

## Mesure avant/après

- Utiliser le même protocole:
  - même device,
  - même dataset,
  - même réseau,
  - 5 runs/scénario.
- Remplir `docs/Temp/perf_android_baseline_runs.csv` pour baseline et rerun.
