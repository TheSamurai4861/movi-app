import argparse
import hashlib
import json
import os
import re
import unicodedata
from pathlib import Path


BACKTICK_RE = re.compile(r"`([^`\n]+)`")


def fold_ascii(s: str) -> str:
    return (
        unicodedata.normalize("NFKD", s)
        .encode("ascii", "ignore")
        .decode("ascii")
    )


def make_key(text: str) -> str:
    base = fold_ascii(text).lower()
    base = re.sub(r"\$\{[^}]+\}", " placeholder ", base)
    base = re.sub(r"\$[a-zA-Z_]\w*", " placeholder ", base)
    base = re.sub(r"[^a-z0-9]+", " ", base).strip()
    words = [w for w in base.split() if w not in {"the", "a", "an", "de", "la", "le", "les", "des", "du", "et", "ou"}]
    words = words[:8] if words else ["text"]
    slug = "_".join(words)
    h = hashlib.sha1(text.encode("utf-8")).hexdigest()[:8]
    return f"hc_{slug}_{h}"


def is_candidate(fragment: str) -> bool:
    s = fragment.strip()
    if not s:
        return False
    # ignore file paths and code-ish snippets
    if "/" in s or "\\" in s:
        return False
    if s.endswith(".dart") or s.endswith(".arb") or s.endswith(".md") or s.endswith(".yaml") or s.endswith(".txt"):
        return False
    if "lib/src" in s or "output/" in s or "lib/l10n" in s:
        return False
    if re.search(r"[(){}\\]|\\b|\\s\*|\[|\]", s):
        return False
    if s.startswith("@"):
        return False
    # ignore keys already like existing ARB keys
    if re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]*", s) and s[0].islower():
        # e.g. actionCancel, settingsTitle
        return False
    # keep short useful UI strings and also longer sentences
    return True


def extract_strings(md_path: Path) -> list[str]:
    content = md_path.read_text(encoding="utf-8", errors="replace")
    frags = [m.group(1) for m in BACKTICK_RE.finditer(content)]
    # de-dup preserving order
    seen = set()
    out: list[str] = []
    for f in frags:
        if not is_candidate(f):
            continue
        if f not in seen:
            seen.add(f)
            out.append(f)
    return out


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", required=True, help="Path to merged markdown report")
    ap.add_argument("--arb-dir", required=True, help="Directory containing app_*.arb files")
    args = ap.parse_args()

    report_path = Path(args.report)
    arb_dir = Path(args.arb_dir)
    if not report_path.exists():
        raise SystemExit(f"Report not found: {report_path}")
    if not arb_dir.exists():
        raise SystemExit(f"arb-dir not found: {arb_dir}")

    strings = extract_strings(report_path)
    if not strings:
        print("No candidate strings extracted from report.")
        return 0

    arb_files = sorted(arb_dir.glob("app_*.arb"))
    if not arb_files:
        raise SystemExit(f"No app_*.arb found in {arb_dir}")

    # Build a stable key map for the run
    key_map: dict[str, str] = {}
    used_keys = set()
    for s in strings:
        k = make_key(s)
        # ensure uniqueness even on collisions
        kk = k
        i = 2
        while kk in used_keys:
            kk = f"{k}_{i}"
            i += 1
        used_keys.add(kk)
        key_map[kk] = s

    added_total = 0
    for arb_path in arb_files:
        data = load_json(arb_path)
        added = 0
        for k, v in key_map.items():
            if k not in data:
                data[k] = v
                added += 1
        if added:
            save_json(arb_path, data)
            added_total += added
        print(f"{arb_path.name}: +{added}")

    print(f"Done. Added total entries across locales: {added_total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

