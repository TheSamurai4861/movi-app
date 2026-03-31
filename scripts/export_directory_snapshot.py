#!/usr/bin/env python3
"""
Génère un rapport Markdown contenant :
1) l'arborescence d'un dossier
2) un snapshot textuel de chaque fichier, avec son chemin au-dessus

Exemple :
    python export_directory_snapshot.py ./mon_dossier -o snapshot.md

Options utiles :
    --max-lines 80
    --max-chars 4000
    --include-hidden
    --exclude-dir .git --exclude-dir node_modules
"""

from __future__ import annotations

import argparse
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


DEFAULT_EXCLUDED_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".idea",
    ".vscode",
    ".venv",
    "venv",
    "__pycache__",
    "node_modules",
    "dist",
    "build",
    ".dart_tool",
}


@dataclass(frozen=True)
class SnapshotConfig:
    root_directory: Path
    output_file: Path
    max_lines_per_file: int = 80
    max_characters_per_file: int = 4000
    include_hidden: bool = False
    excluded_directories: set[str] = field(default_factory=set)


def parse_arguments() -> SnapshotConfig:
    parser = argparse.ArgumentParser(
        description=(
            "Extrait l'arborescence d'un dossier et un snapshot de chaque fichier "
            "dans un rapport Markdown."
        )
    )
    parser.add_argument(
        "source_directory",
        type=Path,
        help="Chemin du dossier à analyser.",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("directory_snapshot.md"),
        help="Fichier Markdown de sortie (défaut : directory_snapshot.md).",
    )
    parser.add_argument(
        "--max-lines",
        type=int,
        default=80,
        help="Nombre maximum de lignes par snapshot de fichier.",
    )
    parser.add_argument(
        "--max-chars",
        type=int,
        default=4000,
        help="Nombre maximum de caractères par snapshot de fichier.",
    )
    parser.add_argument(
        "--include-hidden",
        action="store_true",
        help="Inclut les fichiers et dossiers cachés.",
    )
    parser.add_argument(
        "--exclude-dir",
        action="append",
        default=[],
        help="Nom d'un dossier à exclure. Option répétable.",
    )

    args = parser.parse_args()

    root_directory = args.source_directory.expanduser().resolve()
    output_file = args.output.expanduser().resolve()

    if not root_directory.exists():
        raise FileNotFoundError(f"Le dossier source n'existe pas : {root_directory}")

    if not root_directory.is_dir():
        raise NotADirectoryError(f"Le chemin source n'est pas un dossier : {root_directory}")

    if args.max_lines <= 0:
        raise ValueError("--max-lines doit être supérieur à 0.")

    if args.max_chars <= 0:
        raise ValueError("--max-chars doit être supérieur à 0.")

    excluded_directories = set(DEFAULT_EXCLUDED_DIRS)
    excluded_directories.update(args.exclude_dir)

    return SnapshotConfig(
        root_directory=root_directory,
        output_file=output_file,
        max_lines_per_file=args.max_lines,
        max_characters_per_file=args.max_chars,
        include_hidden=args.include_hidden,
        excluded_directories=excluded_directories,
    )


def is_hidden(path: Path) -> bool:
    return path.name.startswith(".")


def should_skip_directory(path: Path, config: SnapshotConfig) -> bool:
    if path.name in config.excluded_directories:
        return True

    if not config.include_hidden and is_hidden(path):
        return True

    return False


def should_skip_file(path: Path, config: SnapshotConfig) -> bool:
    if not config.include_hidden and is_hidden(path):
        return True

    return False


def list_directory_entries(directory: Path, config: SnapshotConfig) -> list[Path]:
    entries: list[Path] = []

    for entry in directory.iterdir():
        if entry.is_dir():
            if should_skip_directory(entry, config):
                continue
        else:
            if should_skip_file(entry, config):
                continue

        entries.append(entry)

    return sorted(entries, key=lambda item: (item.is_file(), item.name.lower()))


def build_tree_representation(root_directory: Path, config: SnapshotConfig) -> str:
    lines = [f"{root_directory.name}/"]
    append_tree_children(root_directory, prefix="", lines=lines, config=config)
    return "\n".join(lines)


def append_tree_children(
    directory: Path,
    prefix: str,
    lines: list[str],
    config: SnapshotConfig,
) -> None:
    entries = list_directory_entries(directory, config)

    for index, entry in enumerate(entries):
        is_last_entry = index == len(entries) - 1
        branch = "└── " if is_last_entry else "├── "

        if entry.is_symlink():
            try:
                target = entry.resolve(strict=False)
                display_name = f"{entry.name} -> {target}"
            except OSError:
                display_name = f"{entry.name} -> [cible inaccessible]"
            lines.append(f"{prefix}{branch}{display_name}")
            continue

        if entry.is_dir():
            lines.append(f"{prefix}{branch}{entry.name}/")
            child_prefix = f"{prefix}{'    ' if is_last_entry else '│   '}"
            append_tree_children(entry, child_prefix, lines, config=config)
        else:
            lines.append(f"{prefix}{branch}{entry.name}")


def collect_files(root_directory: Path, config: SnapshotConfig) -> list[Path]:
    collected_files: list[Path] = []

    for current_root, dirnames, filenames in os.walk(root_directory, topdown=True):
        current_directory = Path(current_root)

        dirnames[:] = sorted(
            [
                directory_name
                for directory_name in dirnames
                if not should_skip_directory(current_directory / directory_name, config)
            ],
            key=str.lower,
        )

        visible_filenames = sorted(
            [
                filename
                for filename in filenames
                if not should_skip_file(current_directory / filename, config)
            ],
            key=str.lower,
        )

        for filename in visible_filenames:
            collected_files.append(current_directory / filename)

    return collected_files


def is_probably_binary_file(file_path: Path) -> bool:
    try:
        with file_path.open("rb") as file:
            sample = file.read(8192)
    except OSError:
        return False

    if not sample:
        return False

    if b"\x00" in sample:
        return True

    try:
        sample.decode("utf-8")
        return False
    except UnicodeDecodeError:
        return True


def read_text_snapshot(file_path: Path, config: SnapshotConfig) -> str:
    characters_read = 0
    lines_read = 0
    collected_lines: list[str] = []
    was_truncated = False

    try:
        with file_path.open("r", encoding="utf-8", errors="replace") as file:
            for line in file:
                if lines_read >= config.max_lines_per_file:
                    was_truncated = True
                    break

                remaining_characters = config.max_characters_per_file - characters_read
                if remaining_characters <= 0:
                    was_truncated = True
                    break

                if len(line) > remaining_characters:
                    collected_lines.append(line[:remaining_characters])
                    was_truncated = True
                    break

                collected_lines.append(line)
                characters_read += len(line)
                lines_read += 1

    except OSError as error:
        return f"[Erreur de lecture : {error}]"

    snapshot = "".join(collected_lines)

    if was_truncated:
        if snapshot and not snapshot.endswith("\n"):
            snapshot += "\n"
        snapshot += "\n[... snapshot tronqué ...]\n"

    if not snapshot.strip():
        return "[Fichier vide]"

    return snapshot


def build_file_section(file_path: Path, root_directory: Path, config: SnapshotConfig) -> str:
    relative_path = file_path.relative_to(root_directory).as_posix()

    try:
        file_size = file_path.stat().st_size
    except OSError:
        file_size = -1

    lines = [
        f"## {relative_path}",
        "",
        f"- Chemin absolu : `{file_path}`",
        f"- Taille : `{file_size}` octets" if file_size >= 0 else "- Taille : `[inconnue]`",
        "",
    ]

    if is_probably_binary_file(file_path):
        lines.extend(
            [
                "_Fichier binaire détecté : aperçu textuel ignoré._",
                "",
            ]
        )
        return "\n".join(lines)

    snapshot = read_text_snapshot(file_path, config)
    lines.extend(
        [
            "```text",
            snapshot.rstrip("\n"),
            "```",
            "",
        ]
    )

    return "\n".join(lines)


def build_markdown_report(config: SnapshotConfig) -> str:
    tree = build_tree_representation(config.root_directory, config)
    files = collect_files(config.root_directory, config)

    report_parts = [
        "# Snapshot de dossier",
        "",
        f"**Dossier analysé :** `{config.root_directory}`",
        "",
        "## Arborescence",
        "",
        "```text",
        tree,
        "```",
        "",
        "## Snapshots des fichiers",
        "",
    ]

    if not files:
        report_parts.append("_Aucun fichier trouvé avec les filtres actuels._")
        report_parts.append("")
        return "\n".join(report_parts)

    for file_path in files:
        report_parts.append(build_file_section(file_path, config.root_directory, config))

    return "\n".join(report_parts)


def write_report(output_file: Path, content: str) -> None:
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(content, encoding="utf-8")


def main() -> int:
    try:
        config = parse_arguments()
        report = build_markdown_report(config)
        write_report(config.output_file, report)
    except Exception as error:
        print(f"Erreur : {error}")
        return 1

    print(f"Rapport généré : {config.output_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())