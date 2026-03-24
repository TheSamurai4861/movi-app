#!/usr/bin/env python3
"""
scripts/export_project_snapshot.py

Génère un fichier .txt unique contenant :
- l'arborescence de assets/ (sans contenu des fichiers)
- le contenu complet de pubspec.yaml
- le contenu complet de .env.example
- le contenu complet de tous les fichiers dans lib/
  avec leur nom et leur chemin relatif

Mise en page choisie : index + sections

Usage :
    python scripts/export_project_snapshot.py

Options :
    python scripts/export_project_snapshot.py --output project_snapshot.txt
    python scripts/export_project_snapshot.py --root /chemin/vers/projet
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional


IGNORED_DIR_NAMES = {
    ".git",
    ".dart_tool",
    ".idea",
    ".vscode",
    "build",
    ".fvm",
    ".gradle",
}

TEXT_FILE_EXTENSIONS = {
    ".dart",
    ".yaml",
    ".yml",
    ".json",
    ".arb",
    ".txt",
    ".md",
    ".env",
    ".example",
    ".gitignore",
    ".toml",
    ".cfg",
    ".ini",
    ".sh",
    ".bat",
    ".ps1",
    ".xml",
    ".html",
    ".css",
    ".js",
    ".ts",
    ".kt",
    ".java",
    ".swift",
    ".plist",
}


@dataclass
class ExportSection:
    index: int
    title: str
    path: Optional[Path]
    kind: str  # "assets_tree" | "file"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Exporte un snapshot textuel d'un projet Flutter."
    )
    parser.add_argument(
        "--output",
        default="project_snapshot.txt",
        help="Nom du fichier .txt de sortie (par défaut: project_snapshot.txt).",
    )
    parser.add_argument(
        "--root",
        default=None,
        help="Chemin explicite vers la racine du projet Flutter. "
        "Si absent, la racine est déduite automatiquement.",
    )
    return parser.parse_args()


def find_project_root(start_dir: Path) -> Path:
    """
    Remonte depuis le dossier du script jusqu'à trouver pubspec.yaml.
    """
    current = start_dir.resolve()

    for directory in [current, *current.parents]:
        if (directory / "pubspec.yaml").exists():
            return directory

    raise FileNotFoundError(
        "Impossible de trouver la racine du projet Flutter : pubspec.yaml introuvable."
    )


def normalize_relative_path(path: Path, root: Path) -> str:
    try:
        return "/" + path.resolve().relative_to(root.resolve()).as_posix()
    except Exception:
        try:
            return "/" + path.relative_to(root).as_posix()
        except Exception:
            return str(path)


def should_ignore_dir(path: Path) -> bool:
    return path.name in IGNORED_DIR_NAMES


def is_inside_ignored_dir(path: Path, root: Path) -> bool:
    try:
        relative_parts = path.relative_to(root).parts
    except Exception:
        relative_parts = path.parts
    return any(part in IGNORED_DIR_NAMES for part in relative_parts)


def is_probably_text_file(path: Path) -> bool:
    """
    Heuristique simple :
    - extensions textuelles connues => texte
    - sinon, lecture binaire d'un petit chunk et détection de NULL bytes
    """
    if path.suffix.lower() in TEXT_FILE_EXTENSIONS:
        return True

    try:
        with path.open("rb") as f:
            chunk = f.read(4096)
        if b"\x00" in chunk:
            return False
        return True
    except Exception:
        return False


def read_text_file(path: Path) -> str:
    encodings_to_try = ["utf-8", "utf-8-sig", "latin-1"]

    for encoding in encodings_to_try:
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
        except Exception as exc:
            return f"[ERREUR DE LECTURE] {type(exc).__name__}: {exc}"

    return "[ERREUR DE LECTURE] Encodage non supporté."


def safe_iterdir(directory: Path) -> List[Path]:
    try:
        return list(directory.iterdir())
    except Exception:
        return []


def build_ascii_tree(root_dir: Path, base_label: str = "") -> str:
    """
    Construit une arborescence ASCII de type :

    assets/
    ├── icons/
    │   └── play.svg
    └── images/
        └── splash.png

    Robuste :
    - gère les erreurs d'accès
    - ne suit pas les symlinks de dossiers
    """
    root_name = base_label or root_dir.name

    if not root_dir.exists():
        return f"{root_name}/\n[DOSSIER INTROUVABLE]"

    if not root_dir.is_dir():
        return f"{root_name}/\n[ERREUR] Le chemin existe mais n'est pas un dossier."

    lines: List[str] = [f"{root_name}/"]

    def walk(directory: Path, prefix: str = "") -> None:
        try:
            raw_children = safe_iterdir(directory)
            children = []
            for p in raw_children:
                if should_ignore_dir(p):
                    continue
                children.append(p)

            children.sort(key=lambda p: (not p.is_dir(), p.name.lower()))
        except Exception as exc:
            lines.append(f"{prefix}[ERREUR D'ACCÈS] {type(exc).__name__}: {exc}")
            return

        for index, child in enumerate(children):
            is_last = index == len(children) - 1
            branch = "└── " if is_last else "├── "

            try:
                is_dir = child.is_dir()
                is_symlink = child.is_symlink()
            except Exception as exc:
                lines.append(
                    f"{prefix}{branch}{child.name} [ERREUR MÉTADONNÉES: {type(exc).__name__}: {exc}]"
                )
                continue

            if is_dir:
                display_name = f"{child.name}/"
                if is_symlink:
                    display_name = f"{child.name}/ [symlink non suivi]"
                lines.append(f"{prefix}{branch}{display_name}")

                if not is_symlink:
                    extension = "    " if is_last else "│   "
                    walk(child, prefix + extension)
            else:
                display_name = child.name
                if is_symlink:
                    display_name = f"{child.name} [symlink]"
                lines.append(f"{prefix}{branch}{display_name}")

    walk(root_dir)
    return "\n".join(lines)


def collect_lib_files(lib_dir: Path, project_root: Path) -> List[Path]:
    """
    Collecte tous les fichiers de lib/ en ignorant certains dossiers techniques
    et en évitant de suivre les symlinks de dossiers.
    """
    if not lib_dir.exists() or not lib_dir.is_dir():
        return []

    collected: List[Path] = []

    def walk(directory: Path) -> None:
        children = safe_iterdir(directory)

        for child in children:
            try:
                if is_inside_ignored_dir(child, project_root):
                    continue

                if child.is_symlink():
                    # symlink fichier autorisé, symlink dossier ignoré
                    if child.is_dir():
                        continue
                    if child.is_file():
                        collected.append(child)
                    continue

                if child.is_dir():
                    walk(child)
                elif child.is_file():
                    collected.append(child)
            except Exception:
                # On ignore silencieusement ici ;
                # l'erreur éventuelle apparaîtra plus tard si le fichier est traité.
                continue

    walk(lib_dir)
    return sorted(collected, key=lambda p: normalize_relative_path(p, project_root).lower())


def format_separator(title: str, width: int = 50) -> str:
    line = "=" * width
    return f"{line}\n{title}\n{line}"


def format_file_section(index: int, path: Path, project_root: Path) -> str:
    relative_path = normalize_relative_path(path, project_root)
    file_name = path.name

    try:
        if not path.exists():
            content = "[FICHIER INTROUVABLE]"
        elif not path.is_file():
            content = "[CHEMIN NON VALIDE] Le chemin n'est pas un fichier."
        elif not is_probably_text_file(path):
            content = "[FICHIER IGNORÉ : contenu non textuel ou binaire]"
        else:
            content = read_text_file(path).rstrip()
    except Exception as exc:
        content = f"[ERREUR DE TRAITEMENT] {type(exc).__name__}: {exc}"

    return (
        f"{'=' * 50}\n"
        f"[{index}] FILE: {file_name}\n"
        f"PATH: {relative_path}\n"
        f"{'=' * 50}\n\n"
        f"{content}\n"
    )


def build_sections(project_root: Path) -> List[ExportSection]:
    assets_dir = project_root / "assets"
    pubspec_file = project_root / "pubspec.yaml"
    env_example_file = project_root / ".env.example"
    lib_dir = project_root / "lib"

    sections: List[ExportSection] = []
    current_index = 1

    sections.append(
        ExportSection(
            index=current_index,
            title="Assets tree",
            path=assets_dir,
            kind="assets_tree",
        )
    )
    current_index += 1

    if pubspec_file.exists():
        sections.append(
            ExportSection(
                index=current_index,
                title="pubspec.yaml",
                path=pubspec_file,
                kind="file",
            )
        )
        current_index += 1

    if env_example_file.exists():
        sections.append(
            ExportSection(
                index=current_index,
                title=".env.example",
                path=env_example_file,
                kind="file",
            )
        )
        current_index += 1

    lib_files = collect_lib_files(lib_dir, project_root)
    for file_path in lib_files:
        sections.append(
            ExportSection(
                index=current_index,
                title=normalize_relative_path(file_path, project_root).lstrip("/"),
                path=file_path,
                kind="file",
            )
        )
        current_index += 1

    return sections


def build_output(project_root: Path) -> str:
    sections = build_sections(project_root)
    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    parts: List[str] = []

    parts.append(format_separator("FLUTTER EXPORT"))
    parts.append(f"\nROOT: {project_root.as_posix()}")
    parts.append(f"GENERATED_AT: {generated_at}\n")

    parts.append(format_separator("[INDEX]"))
    index_lines = [f"{section.index}. {section.title}" for section in sections]
    parts.append("\n" + "\n".join(index_lines) + "\n")

    for section in sections:
        if section.kind == "assets_tree":
            parts.append(format_separator(f"[{section.index}] ASSETS TREE"))
            parts.append("")
            parts.append(build_ascii_tree(section.path, "assets") if section.path else "[DOSSIER INTROUVABLE]")
            parts.append("")
        elif section.kind == "file":
            if section.path is None:
                parts.append(
                    f"{'=' * 50}\n"
                    f"[{section.index}] FILE: [INCONNU]\n"
                    f"PATH: [INCONNU]\n"
                    f"{'=' * 50}\n\n"
                    f"[ERREUR] Section sans chemin.\n"
                )
            else:
                parts.append(format_file_section(section.index, section.path, project_root))

    return "\n".join(parts).rstrip() + "\n"


def validate_project_root(project_root: Path) -> None:
    if not project_root.exists():
        raise FileNotFoundError(f"Le dossier racine n'existe pas : {project_root}")

    if not project_root.is_dir():
        raise NotADirectoryError(f"Le chemin racine n'est pas un dossier : {project_root}")

    if not (project_root / "pubspec.yaml").exists():
        raise FileNotFoundError(
            f"pubspec.yaml introuvable dans la racine indiquée : {project_root}"
        )


def write_output_file(output_file: Path, content: str) -> None:
    try:
        output_file.write_text(content, encoding="utf-8")
    except Exception as exc:
        raise OSError(
            f"Impossible d'écrire le fichier de sortie '{output_file}': "
            f"{type(exc).__name__}: {exc}"
        ) from exc


def main() -> int:
    args = parse_args()

    try:
        if args.root:
            project_root = Path(args.root).resolve()
        else:
            script_dir = Path(__file__).resolve().parent
            project_root = find_project_root(script_dir)

        validate_project_root(project_root)

        output_file = Path(args.output)
        if not output_file.is_absolute():
            output_file = project_root / output_file

        content = build_output(project_root)
        write_output_file(output_file, content)

        print(f"Export terminé : {output_file.as_posix()}")
        return 0

    except KeyboardInterrupt:
        print("Export interrompu par l'utilisateur.", file=sys.stderr)
        return 130
    except Exception as exc:
        print(f"Erreur : {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())