import os
from pathlib import Path

def dump_folder_to_txt(folder_path: str, output_file: str = "dump.txt") -> None:
    """
    Copies the content of each file (recursively) from `folder_path` into `output_file`.
    Adds a header line with the absolute path before each file's content.

    - Skips binary-ish files by simple heuristic.
    - Skips common build/hidden folders.
    """
    root = Path(folder_path).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        raise ValueError(f"Folder not found or not a directory: {root}")

    skip_dirs = {
        ".git", ".dart_tool", "build", ".idea", ".vscode", ".metadata",
        "ios", "android", "linux", "macos", "windows", "web"
    }

    def is_probably_text(file_path: Path, sample_size: int = 4096) -> bool:
        try:
            data = file_path.read_bytes()[:sample_size]
        except Exception:
            return False
        if b"\x00" in data:
            return False
        # if a lot of bytes are non-ascii control chars, likely binary
        control = sum(1 for b in data if b < 9 or (13 < b < 32))
        return control / max(1, len(data)) < 0.05

    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        # prune skipped dirs
        dirnames[:] = [d for d in dirnames if d not in skip_dirs and not d.startswith(".")]

        for name in filenames:
            p = Path(dirpath) / name
            if p.name.startswith("."):
                continue
            files.append(p)

    files.sort(key=lambda p: str(p).lower())

    out = Path(output_file).expanduser().resolve()
    with out.open("w", encoding="utf-8") as f:
        f.write(f"# DUMP FROM: {root}\n\n")

        for file_path in files:
            if not file_path.is_file():
                continue

            # Only dump text-like files (Dart/MD/YAML/JSON/etc.)
            if not is_probably_text(file_path):
                continue

            try:
                content = file_path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                # fallback
                content = file_path.read_text(encoding="latin-1", errors="replace")
            except Exception as e:
                f.write(f"\n\n===== FILE: {file_path} =====\n")
                f.write(f"[ERROR READING FILE: {e}]\n")
                continue

            f.write("\n\n" + "=" * 120 + "\n")
            f.write(f"FILE: {file_path}\n")
            f.write("=" * 120 + "\n\n")
            f.write(content)

    print(f"Dump written to: {out}")

if __name__ == "__main__":
    # Example usage:
    # dump_folder_to_txt(r"C:\USERS\MATTE\DOCUMENTS\DEV\FLUTTER\MOVI-APP\LIB\src\core\startup", "dump.txt")
    import sys
    if len(sys.argv) < 2:
        print("Usage: python dump_core_folder.py <folder_path> [output_file]")
        raise SystemExit(1)

    folder = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) >= 3 else "dump.txt"
    dump_folder_to_txt(folder, output)
