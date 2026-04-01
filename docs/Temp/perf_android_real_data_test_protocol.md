# Protocole Perf Android (Données Réelles In-App)

## Objectif

Mesurer la performance réelle de l'app Android sur appareil physique avec un dataset réel, puis identifier des améliorations priorisées.

## Setup Référence

- Device: Android physique (modèle + version OS à remplir dans le tableau de runs).
- Build: `flutter run --profile --dart-define-from-file=.env`
- Réseau: Wi-Fi stable, même position et même heure de test autant que possible.
- Dataset figé:
  - 1 profil principal (adulte)
  - 1 source IPTV active réelle
  - bibliothèque réelle existante (historique + favoris)

## KPI Mesurés

- `startup_to_home_ready_ms`: cold start -> home interactif
- `home_scroll_jank_rate`: ratio de frames jank pendant scroll Home
- `detail_open_ms`: tap carte -> écran détail visible
- `player_open_ms`: tap lecture -> first frame player visible
- `sheet_open_ms`: ouverture sheet audio/sous-titres
- `network_slow_count`: nombre de `SLOW REQUEST` pendant scénario

## Budgets Cibles (P95)

- startup_to_home_ready_ms <= 3500ms
- detail_open_ms <= 1200ms
- player_open_ms <= 1400ms
- sheet_open_ms <= 300ms
- home_scroll_jank_rate <= 3%

## Scénarios

- `S1`: Cold start -> Home interactif
- `S2`: Home scroll (hero + sections IPTV) pendant 20s
- `S3`: Home -> détail film/série
- `S4`: Détail -> player + ouverture sheet audio/sous-titres
- `S5`: Settings -> Sources -> retour Home

## Méthode

1. Faire 5 runs par scénario (cold/warm selon scénario).
2. Capturer:
   - logs runtime (`[AppLaunch]`, `[Launch]`, `[HomeLoad]`, `[PerfDiag]`, `[Network]`),
   - trace DevTools Performance (timeline).
3. Reporter les mesures dans:
   - `docs/Temp/perf_android_baseline_runs.csv`
   - `docs/Temp/perf_android_hotspots_and_backlog.md`

## Commandes utiles

```powershell
# Build profile
flutter run --profile --dart-define-from-file=.env

# Générer un résumé auto depuis un fichier log runtime
python "scripts/perf/extract_perf_metrics_from_log.py" `
  --input "C:\path\to\runtime_log.txt" `
  --output "docs/Temp/perf_android_baseline_summary.md"
```

## Critères d'arrêt

- Baseline complète = 5 runs * 5 scénarios.
- Au moins 3 hotspots exploitables identifiés.
- Backlog P0/P1 rédigé avec gain attendu + risque.
