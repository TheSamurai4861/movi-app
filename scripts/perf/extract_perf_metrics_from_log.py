#!/usr/bin/env python3
"""Extracts coarse performance metrics from Flutter runtime logs.

Usage:
  python scripts/perf/extract_perf_metrics_from_log.py \
    --input "path/to/flutter_log.txt" \
    --output "docs/Temp/perf_android_baseline_from_log.md"
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from statistics import median


LAUNCH_START_RE = re.compile(r"\[AppLaunch\].*action=run")
LAUNCH_DONE_RE = re.compile(r"\[Launch\].*phase=done status=success")
HOMELOAD_END_RE = re.compile(r"\[HomeLoad\].*action=end .*reason=([a-zA-Z]+).*duration=(\d+)ms")
PERFDIAG_DONE_RE = re.compile(r"\[PerfDiag\].*event=completed.*durationMs=(\d+).*op=([a-zA-Z0-9_]+)")
SLOW_REQ_RE = re.compile(r"\[Network\] SLOW REQUEST")


@dataclass
class ParseStats:
    app_launch_runs: int = 0
    app_launch_success: int = 0
    slow_requests: int = 0
    home_preload_durations_ms: list[int] | None = None
    home_profile_change_durations_ms: list[int] | None = None
    iptv_synced_durations_ms: list[int] | None = None
    perf_ops: dict[str, list[int]] | None = None

    def __post_init__(self) -> None:
        self.home_preload_durations_ms = []
        self.home_profile_change_durations_ms = []
        self.iptv_synced_durations_ms = []
        self.perf_ops = {}


def parse_lines(lines: list[str]) -> ParseStats:
    stats = ParseStats()
    for line in lines:
        if LAUNCH_START_RE.search(line):
            stats.app_launch_runs += 1
        if LAUNCH_DONE_RE.search(line):
            stats.app_launch_success += 1
        if SLOW_REQ_RE.search(line):
            stats.slow_requests += 1

        m_home = HOMELOAD_END_RE.search(line)
        if m_home:
            reason = m_home.group(1)
            duration = int(m_home.group(2))
            if reason == "preload":
                stats.home_preload_durations_ms.append(duration)
            elif reason == "profileChange":
                stats.home_profile_change_durations_ms.append(duration)
            elif reason == "iptvSynced":
                stats.iptv_synced_durations_ms.append(duration)

        m_perf = PERFDIAG_DONE_RE.search(line)
        if m_perf:
            duration = int(m_perf.group(1))
            op = m_perf.group(2)
            if op not in stats.perf_ops:
                stats.perf_ops[op] = []
            stats.perf_ops[op].append(duration)

    return stats


def _fmt_dist(values: list[int]) -> str:
    if not values:
        return "n/a"
    return (
        f"count={len(values)}, min={min(values)}ms, "
        f"median={int(median(values))}ms, p95~={sorted(values)[int(0.95 * (len(values) - 1))]}ms, "
        f"max={max(values)}ms"
    )


def render_markdown(stats: ParseStats, input_path: Path) -> str:
    lines: list[str] = []
    lines.append("# Android Perf Log Summary")
    lines.append("")
    lines.append(f"- Source: `{input_path}`")
    lines.append(f"- App launch runs seen: **{stats.app_launch_runs}**")
    lines.append(f"- App launch success seen: **{stats.app_launch_success}**")
    lines.append(f"- Network slow requests seen: **{stats.slow_requests}**")
    lines.append("")
    lines.append("## HomeLoad Durations")
    lines.append("")
    lines.append(f"- preload: {_fmt_dist(stats.home_preload_durations_ms)}")
    lines.append(f"- profileChange: {_fmt_dist(stats.home_profile_change_durations_ms)}")
    lines.append(f"- iptvSynced: {_fmt_dist(stats.iptv_synced_durations_ms)}")
    lines.append("")
    lines.append("## PerfDiag Operations")
    lines.append("")
    if not stats.perf_ops:
        lines.append("- n/a")
    else:
        for op in sorted(stats.perf_ops.keys()):
            lines.append(f"- {op}: {_fmt_dist(stats.perf_ops[op])}")
    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append(
        "- This parser is best-effort and relies on current log formats (`[HomeLoad]`, `[PerfDiag]`, `[AppLaunch]`)."
    )
    lines.append("- Use it for trend comparison (before/after), not as a profiler replacement.")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Path to runtime log file")
    parser.add_argument("--output", required=True, help="Markdown output path")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        raise FileNotFoundError(f"Input log not found: {input_path}")

    content = input_path.read_text(encoding="utf-8", errors="ignore")
    stats = parse_lines(content.splitlines())
    output = render_markdown(stats, input_path)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(output, encoding="utf-8")
    print(f"Written summary: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
