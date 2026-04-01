# Rerun Seed (Avant Quick Wins)

Source baseline seed: `docs/Temp/perf_android_baseline_summary.md`

## Valeurs avant (seed)

- app_launch_runs_seen: 1
- app_launch_success_seen: 1
- network_slow_requests_seen: 1
- home_preload_duration_ms: min=0, median=92, max=185
- home_profile_change_duration_ms: median=721

## Rerun après quick wins (à remplir)

- app_launch_runs_seen:
- app_launch_success_seen:
- network_slow_requests_seen:
- home_preload_duration_ms (min/median/max):
- home_profile_change_duration_ms (median):

## Commande rerun

```powershell
python "scripts/perf/extract_perf_metrics_from_log.py" `
  --input "path/to/perf_rerun.log" `
  --output "docs/Temp/perf_android_rerun_summary.md"
```

Comparer ensuite avec:
- `docs/Temp/perf_android_baseline_summary.md`
- `docs/Temp/perf_android_rerun_comparison_template.md`
