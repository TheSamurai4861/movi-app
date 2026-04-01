import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
L10N_DIR = ROOT / "lib" / "l10n"
TEMPLATE = L10N_DIR / "app_en.arb"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def normalize_locale(tag: str) -> str:
    """
    Accepts: 'ar', 'ar_SA', 'zh_Hans', 'pt_BR' ...
    Outputs file suffix part used after 'app_'.
    """
    tag = tag.strip()
    if not tag:
        raise ValueError("Empty locale tag")
    # Flutter gen-l10n convention for arb filenames uses underscores.
    tag = tag.replace("-", "_")
    return tag


def main() -> int:
    ap = argparse.ArgumentParser(description="Add a new ARB locale file based on app_en.arb")
    ap.add_argument("locale", help="Locale tag (e.g. ar, tr, ru, uk, ja, ko, zh_Hans, pt_BR)")
    ap.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing app_<locale>.arb if it already exists",
    )
    args = ap.parse_args()

    locale = normalize_locale(args.locale)
    if not TEMPLATE.exists():
        raise SystemExit(f"Template not found: {TEMPLATE}")

    out = L10N_DIR / f"app_{locale}.arb"
    if out.exists() and not args.overwrite:
        raise SystemExit(f"Already exists: {out} (use --overwrite to replace)")

    data = load_json(TEMPLATE)
    # Keep everything as-is (including @metadata blocks). This guarantees all keys exist.
    save_json(out, data)

    print(f"Created: {out.relative_to(ROOT)}")
    print("Next steps:")
    print(f"- Translate values in {out.name}")
    print("- Run: flutter gen-l10n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

