# Checklist Exécution Baseline (Android)

## Préparation

- [ ] Fermer apps en arrière-plan sur le device.
- [ ] Activer mode avion 10s puis Wi-Fi (stabiliser réseau).
- [ ] Vérifier dataset réel figé (profil/source/library inchangés).
- [ ] Lancer l'app en profile mode:

```powershell
flutter run --profile --dart-define-from-file=.env
```

## Collecte logs (par scénario)

- [ ] Démarrer capture:

```powershell
adb logcat -c
adb logcat > perf_run_sX_rY.log
```

- [ ] Exécuter scénario (`S1..S5`).
- [ ] Arrêter capture (`Ctrl+C`) et archiver le log.
- [ ] Générer résumé:

```powershell
python "scripts/perf/extract_perf_metrics_from_log.py" `
  --input "perf_run_sX_rY.log" `
  --output "docs/Temp/perf_run_sX_rY_summary.md"
```

- [ ] Reporter les KPI dans `docs/Temp/perf_android_baseline_runs.csv`.

## DevTools (timeline)

- [ ] Ouvrir DevTools Performance.
- [ ] Capturer timeline sur chaque scénario.
- [ ] Exporter trace sous `docs/Temp/perf_traces/`.

## Fin baseline

- [ ] Vérifier 5 runs par scénario complétés.
- [ ] Calculer min/median/max + P95.
- [ ] Mettre à jour `docs/Temp/perf_android_hotspots_and_backlog.md`.
