#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Applique automatiquement des fichiers corrigés à un projet existant.

Usage recommandé (Windows, avec `py`) :

1) Place ce script dans le dossier qui contient les corrections.
   Exemple :
   C:\temp\movi_app_phase3_shell\apply_corrections.py

2) Depuis ce dossier, lance :
   py apply_corrections.py --project "C:\Users\matte\Documents\DEV\Flutter\movi-app"

Par défaut, le script copie tous les fichiers trouvés sous le dossier courant
vers le projet cible, en conservant leur chemin relatif.

Options utiles :
- --dry-run   : affiche ce qui serait copié sans rien modifier
- --force     : remplace aussi si le fichier source et la cible sont identiques
- --include-ext .dart .yaml : limite aux extensions données
- --from-root lib src : copie seulement depuis certains dossiers racine
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path


EXCLUDED_DIR_NAMES = {
    ".git",
    ".dart_tool",
    ".idea",
    ".vscode",
    "build",
    "__pycache__",
}

EXCLUDED_FILE_NAMES = {
    "apply_corrections.py",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Copie des fichiers corrigés vers un projet cible en conservant les chemins relatifs."
    )
    parser.add_argument(
        "--project",
        required=True,
        help="Chemin du projet cible à mettre à jour.",
    )
    parser.add_argument(
        "--source",
        default=".",
        help="Dossier contenant les corrections. Par défaut : dossier courant.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Affiche les opérations sans modifier le projet.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Copie aussi les fichiers même s'ils semblent identiques.",
    )
    parser.add_argument(
        "--include-ext",
        nargs="*",
        default=None,
        help="Liste d'extensions à inclure, par exemple: .dart .yaml .md",
    )
    parser.add_argument(
        "--from-root",
        nargs="*",
        default=None,
        help="Sous-dossiers racine à copier uniquement, par exemple: lib test",
    )
    parser.add_argument(
        "--backup-dir",
        default=None,
        help="Dossier de sauvegarde pour les fichiers remplacés. Optionnel.",
    )
    return parser.parse_args()


def normalize_extensions(values: list[str] | None) -> set[str] | None:
    if not values:
        return None
    result = set()
    for value in values:
        ext = value.strip()
        if not ext:
            continue
        if not ext.startswith("."):
            ext = "." + ext
        result.add(ext.lower())
    return result or None


def should_skip_dir(path: Path) -> bool:
    return path.name in EXCLUDED_DIR_NAMES


def should_skip_file(path: Path, include_ext: set[str] | None) -> bool:
    if path.name in EXCLUDED_FILE_NAMES:
        return True
    if include_ext is not None and path.suffix.lower() not in include_ext:
        return True
    return False


def iter_source_files(source_root: Path, include_ext: set[str] | None, from_roots: set[str] | None):
    if from_roots:
        candidate_roots = []
        for name in from_roots:
            candidate = source_root / name
            if candidate.exists() and candidate.is_dir():
                candidate_roots.append(candidate)
            else:
                print(f"[WARN] Racine source introuvable, ignorée: {candidate}")
    else:
        candidate_roots = [source_root]

    for root in candidate_roots:
        for path in root.rglob("*"):
            if path.is_dir():
                continue
            if any(part in EXCLUDED_DIR_NAMES for part in path.parts):
                continue
            if should_skip_file(path, include_ext):
                continue
            yield path


def files_differ(src: Path, dst: Path) -> bool:
    if not dst.exists():
        return True
    try:
        return not filecmp.cmp(src, dst, shallow=False)
    except OSError:
        return True


def copy_file(src: Path, dst: Path, dry_run: bool, backup_dir: Path | None):
    if backup_dir is not None and dst.exists():
        backup_target = backup_dir / dst.relative_to(dst.anchor)
        if not dry_run:
            backup_target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, backup_target)

    if dry_run:
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def main() -> int:
    args = parse_args()

    source_root = Path(args.source).resolve()
    project_root = Path(args.project).resolve()
    include_ext = normalize_extensions(args.include_ext)
    from_roots = set(args.from_root) if args.from_root else None
    backup_dir = Path(args.backup_dir).resolve() if args.backup_dir else None

    if not source_root.exists() or not source_root.is_dir():
        print(f"[ERROR] Dossier source invalide: {source_root}")
        return 1

    if not project_root.exists() or not project_root.is_dir():
        print(f"[ERROR] Dossier projet invalide: {project_root}")
        return 1

    source_files = list(iter_source_files(source_root, include_ext, from_roots))
    if not source_files:
        print("[ERROR] Aucun fichier source à copier.")
        return 1

    copied = 0
    skipped_identical = 0
    scanned = 0

    print(f"[INFO] Source   : {source_root}")
    print(f"[INFO] Projet   : {project_root}")
    print(f"[INFO] Dry-run  : {args.dry_run}")
    print(f"[INFO] Force    : {args.force}")
    if include_ext:
        print(f"[INFO] Ext      : {', '.join(sorted(include_ext))}")
    if from_roots:
        print(f"[INFO] Racines  : {', '.join(sorted(from_roots))}")
    if backup_dir:
        print(f"[INFO] Backup   : {backup_dir}")

    for src in source_files:
        rel = src.relative_to(source_root)
        dst = project_root / rel
        scanned += 1

        if not args.force and not files_differ(src, dst):
            skipped_identical += 1
            print(f"[SKIP] Identique : {rel}")
            continue

        print(f"[COPY] {rel}")
        copy_file(src, dst, args.dry_run, backup_dir)
        copied += 1

    print()
    print("[DONE]")
    print(f"Fichiers scannés   : {scanned}")
    print(f"Fichiers copiés    : {copied}")
    print(f"Fichiers ignorés   : {skipped_identical}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
