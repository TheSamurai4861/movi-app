#!/usr/bin/env python3
"""
Export selected files/folders from a project root into a ZIP archive,
preserving relative paths.

Examples:
  python export_selected_files_root_ready.py ^
    --project-root . ^
    --include-paths lib\\src\\features\\home\\presentation\\pages\\home_page.dart ^
                    lib\\src\\features\\home\\presentation\\widgets\\home_content.dart ^
    --output-zip .\\selected_files.zip ^
    --overwrite

  python export_selected_files_root_ready.py ^
    --project-root . ^
    --include-list-file .\\export_list.txt ^
    --output-zip .\\selected_files.zip ^
    --overwrite
"""

from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Copy selected files/folders and package them into a ZIP."
    )
    parser.add_argument(
        "--project-root",
        default=".",
        help="Project root directory. Default: current directory.",
    )
    parser.add_argument(
        "--include-paths",
        nargs="*",
        default=[],
        help="One or more files/folders to include. Relative to project root or absolute.",
    )
    parser.add_argument(
        "--include-list-file",
        help="Text file containing one file/folder path per line.",
    )
    parser.add_argument(
        "--output-zip",
        default="selected_files.zip",
        help="Output ZIP path. Default: selected_files.zip",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite output ZIP if it already exists.",
    )
    return parser.parse_args()


def load_paths(args: argparse.Namespace) -> list[str]:
    items = list(args.include_paths or [])

    if args.include_list_file:
        list_file = Path(args.include_list_file).expanduser().resolve()
        if not list_file.exists():
            raise FileNotFoundError(f"Include list file not found: {list_file}")
        for line in list_file.read_text(encoding="utf-8").splitlines():
            cleaned = line.strip()
            if not cleaned or cleaned.startswith("#"):
                continue
            items.append(cleaned)

    # Remove duplicates while preserving order
    seen: set[str] = set()
    unique_items: list[str] = []
    for item in items:
        key = item.strip()
        if not key or key in seen:
            continue
        seen.add(key)
        unique_items.append(key)

    if not unique_items:
        raise ValueError("No input paths provided. Use --include-paths and/or --include-list-file.")
    return unique_items


def resolve_input_path(raw_path: str, project_root: Path) -> tuple[Path, Path]:
    raw = Path(raw_path).expanduser()

    if raw.is_absolute():
        absolute = raw.resolve()
    else:
        absolute = (project_root / raw).resolve()

    if not absolute.exists():
        raise FileNotFoundError(f"Path not found: {raw_path}")

    try:
        relative = absolute.relative_to(project_root)
    except ValueError as exc:
        raise ValueError(
            f"Path is outside project root and cannot be exported with project structure preserved: {raw_path}"
        ) from exc

    return absolute, relative


def copy_file(src: Path, dst: Path) -> int:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return 1


def copy_directory(src_dir: Path, dst_dir: Path) -> int:
    count = 0
    for src in src_dir.rglob("*"):
        if src.is_file():
            relative = src.relative_to(src_dir)
            dst = dst_dir / relative
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            count += 1
    return count


def main() -> int:
    args = parse_args()

    project_root = Path(args.project_root).expanduser().resolve()
    if not project_root.exists() or not project_root.is_dir():
        raise FileNotFoundError(f"Project root not found: {project_root}")

    include_items = load_paths(args)

    output_zip = Path(args.output_zip).expanduser()
    if not output_zip.is_absolute():
        output_zip = (project_root / output_zip).resolve()

    if output_zip.exists() and not args.overwrite:
        raise FileExistsError(
            f"Output ZIP already exists: {output_zip}. Use --overwrite to replace it."
        )

    output_zip.parent.mkdir(parents=True, exist_ok=True)
    if output_zip.exists():
        output_zip.unlink()

    copied_files = 0

    with tempfile.TemporaryDirectory(prefix="export_selected_files_") as temp_dir_str:
        staging_root = Path(temp_dir_str)

        for item in include_items:
            absolute, relative = resolve_input_path(item, project_root)
            destination = staging_root / relative

            if absolute.is_file():
                copied_files += copy_file(absolute, destination)
            elif absolute.is_dir():
                copied_files += copy_directory(absolute, destination)
            else:
                raise ValueError(f"Unsupported path type: {item}")

        base_name = str(output_zip.with_suffix(""))
        archive_path = shutil.make_archive(base_name, "zip", root_dir=staging_root)

    print(f"Project root : {project_root}")
    print(f"Output ZIP   : {archive_path}")
    print(f"Files copied : {copied_files}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
