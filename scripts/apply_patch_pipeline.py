#!/usr/bin/env python3
# python scripts/apply_patch_pipeline.py --project-root . --input-json scripts/data/patches.json
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from enum import IntEnum
from pathlib import Path, PurePosixPath
from typing import Any


class ExitCode(IntEnum):
    SUCCESS = 0
    INPUT_ERROR = 1
    FILE_WRITE_ERROR = 2
    FORMAT_FAILED = 3
    ANALYZE_FAILED = 4
    TESTS_FAILED = 5
    UNEXPECTED_ERROR = 10


class PipelineError(Exception):
    """Erreur métier du pipeline."""


class InputJsonError(PipelineError):
    """Erreur liée au JSON d'entrée."""


class UnsafeRelativePathError(PipelineError):
    """Erreur levée lorsqu'un chemin cible sort de la racine projet."""


@dataclass(frozen=True)
class PatchFileSpec:
    relative_path: str
    content: str


@dataclass(frozen=True)
class WrittenFileResult:
    relative_path: str
    absolute_path: str
    existed_before_write: bool
    is_dart_file: bool
    is_added_test_file: bool


@dataclass(frozen=True)
class CommandExecutionResult:
    command: list[str]
    working_directory: str
    exit_code: int
    stdout: str
    stderr: str
    command_not_found: bool = False

    @property
    def succeeded(self) -> bool:
        return self.exit_code == 0 and not self.command_not_found


@dataclass(frozen=True)
class ToolingContext:
    flutter_executable: str | None
    dart_executable: str | None
    environment: dict[str, str]
    flutter_sdk_bin: str | None
    flutter_root: str | None

    def flutter_command(self, *args: str) -> list[str]:
        if self.flutter_executable is None:
            return ["flutter", *args]
        return [self.flutter_executable, *args]

    def dart_command(self, *args: str) -> list[str]:
        if self.dart_executable is None:
            return ["dart", *args]
        return [self.dart_executable, *args]


@dataclass(frozen=True)
class PipelineReport:
    timestamp_utc: str
    project_root: str
    input_json_path: str
    output_directory: str
    written_files: list[WrittenFileResult]
    dart_files_formatted: list[str]
    added_test_files: list[str]
    tooling_context: ToolingContext
    dart_format_result: CommandExecutionResult
    flutter_analyze_result: CommandExecutionResult
    flutter_test_results: list[CommandExecutionResult]
    final_exit_code: int

def print_progress(message: str) -> None:
    print(message, flush=True)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Remplace entièrement des fichiers depuis un JSON, exécute dart format, "
            "flutter analyze, puis les nouveaux tests ajoutés si analyze passe."
        )
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Racine du projet Flutter/Dart. Défaut : répertoire courant.",
    )
    parser.add_argument(
        "--input-json",
        type=Path,
        required=True,
        help="Chemin du fichier JSON contenant les fichiers à écrire.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("output"),
        help="Dossier de sortie pour les logs et le résumé. Défaut : output/",
    )
    return parser.parse_args()


def resolve_project_root(project_root_argument: Path) -> Path:
    project_root = project_root_argument.expanduser().resolve()

    if not project_root.exists():
        raise PipelineError(f"La racine projet n'existe pas : {project_root}")

    if not project_root.is_dir():
        raise PipelineError(f"La racine projet n'est pas un dossier : {project_root}")

    return project_root


def resolve_input_json_path(input_json_argument: Path) -> Path:
    input_json_path = input_json_argument.expanduser().resolve()

    if not input_json_path.exists():
        raise InputJsonError(f"Le fichier JSON d'entrée n'existe pas : {input_json_path}")

    if not input_json_path.is_file():
        raise InputJsonError(f"Le chemin JSON d'entrée n'est pas un fichier : {input_json_path}")

    return input_json_path


def resolve_output_directory(project_root: Path, output_dir_argument: Path) -> Path:
    if output_dir_argument.is_absolute():
        return output_dir_argument.expanduser().resolve()

    return (project_root / output_dir_argument).resolve()


def load_patch_file_specs(input_json_path: Path) -> list[PatchFileSpec]:
    try:
        raw_payload = json.loads(input_json_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise InputJsonError(f"JSON invalide dans {input_json_path}: {error}") from error
    except OSError as error:
        raise InputJsonError(f"Impossible de lire le JSON d'entrée : {error}") from error

    return parse_patch_file_specs(raw_payload)


def parse_patch_file_specs(raw_payload: Any) -> list[PatchFileSpec]:
    if isinstance(raw_payload, list):
        raw_items = raw_payload
    elif isinstance(raw_payload, dict) and isinstance(raw_payload.get("files"), list):
        raw_items = raw_payload["files"]
    else:
        raise InputJsonError(
            "Le JSON doit être soit une liste d'objets, soit un objet contenant une clé 'files'."
        )

    patch_file_specs: list[PatchFileSpec] = []

    for index, raw_item in enumerate(raw_items):
        patch_file_specs.append(parse_patch_file_spec(raw_item, index))

    if not patch_file_specs:
        raise InputJsonError("Le JSON d'entrée ne contient aucun fichier à écrire.")

    return patch_file_specs


def parse_patch_file_spec(raw_item: Any, index: int) -> PatchFileSpec:
    if not isinstance(raw_item, dict):
        raise InputJsonError(f"L'entrée #{index} doit être un objet JSON.")

    if "path" not in raw_item:
        raise InputJsonError(f"L'entrée #{index} ne contient pas la clé 'path'.")

    if "content" not in raw_item:
        raise InputJsonError(f"L'entrée #{index} ne contient pas la clé 'content'.")

    relative_path = raw_item["path"]
    content = raw_item["content"]

    if not isinstance(relative_path, str) or not relative_path.strip():
        raise InputJsonError(f"L'entrée #{index} a un 'path' invalide.")

    if not isinstance(content, str):
        raise InputJsonError(f"L'entrée #{index} a un 'content' invalide : une chaîne est attendue.")

    return PatchFileSpec(relative_path=relative_path, content=content)


def normalize_relative_path(relative_path: str) -> PurePosixPath:
    normalized_path = PurePosixPath(relative_path.replace("\\", "/"))

    if normalized_path.is_absolute():
        raise UnsafeRelativePathError(f"Le chemin doit être relatif : {relative_path}")

    if not normalized_path.parts:
        raise UnsafeRelativePathError(f"Le chemin est vide : {relative_path}")

    for part in normalized_path.parts:
        if part in {".", ".."}:
            raise UnsafeRelativePathError(
                f"Le chemin contient un segment interdit '.' ou '..' : {relative_path}"
            )

    return normalized_path


def resolve_target_file_path(project_root: Path, relative_path: str) -> tuple[Path, str]:
    normalized_relative_path = normalize_relative_path(relative_path)
    target_path = (project_root / Path(*normalized_relative_path.parts)).resolve()

    try:
        target_path.relative_to(project_root)
    except ValueError as error:
        raise UnsafeRelativePathError(
            f"Le chemin sort de la racine projet : {relative_path}"
        ) from error

    return target_path, normalized_relative_path.as_posix()


def is_dart_file(normalized_relative_path: str) -> bool:
    return normalized_relative_path.endswith(".dart")


def is_test_file(normalized_relative_path: str) -> bool:
    is_dart_test_name = normalized_relative_path.endswith("_test.dart")
    is_test_directory = (
        normalized_relative_path.startswith("test/")
        or normalized_relative_path.startswith("integration_test/")
    )
    return is_dart_test_name and is_test_directory


def write_patch_files(
    project_root: Path,
    patch_file_specs: list[PatchFileSpec],
) -> list[WrittenFileResult]:
    written_files: list[WrittenFileResult] = []

    for patch_file_spec in patch_file_specs:
        target_path, normalized_relative_path = resolve_target_file_path(
            project_root=project_root,
            relative_path=patch_file_spec.relative_path,
        )

        if target_path.exists() and target_path.is_dir():
            raise PipelineError(
                f"Impossible d'écrire un fichier car un dossier existe déjà : {target_path}"
            )

        existed_before_write = target_path.exists()
        target_path.parent.mkdir(parents=True, exist_ok=True)

        try:
            target_path.write_text(patch_file_spec.content, encoding="utf-8")
        except OSError as error:
            raise PipelineError(f"Impossible d'écrire le fichier {target_path}: {error}") from error

        written_files.append(
            WrittenFileResult(
                relative_path=normalized_relative_path,
                absolute_path=str(target_path),
                existed_before_write=existed_before_write,
                is_dart_file=is_dart_file(normalized_relative_path),
                is_added_test_file=(not existed_before_write and is_test_file(normalized_relative_path)),
            )
        )

    return written_files


def build_windows_flutter_bin_candidates() -> list[Path]:
    candidate_paths: list[Path] = []

    system_drive = os.environ.get("SystemDrive", "C:")
    user_profile = os.environ.get("USERPROFILE")

    hardcoded_candidates = [
        Path("D:/SDK/flutter/bin"),
        Path("C:/src/flutter/bin"),
        Path("C:/flutter/bin"),
        Path(f"{system_drive}/src/flutter/bin"),
    ]

    if user_profile:
        hardcoded_candidates.extend(
            [
                Path(user_profile) / "flutter" / "bin",
                Path(user_profile) / "development" / "flutter" / "bin",
                Path(user_profile) / "sdk" / "flutter" / "bin",
            ]
        )

    for candidate in hardcoded_candidates:
        resolved_candidate = candidate.expanduser().resolve()
        if resolved_candidate.exists() and resolved_candidate.is_dir():
            candidate_paths.append(resolved_candidate)

    return deduplicate_paths(candidate_paths)


def build_environment_flutter_bin_candidates() -> list[Path]:
    candidate_paths: list[Path] = []

    flutter_root = os.environ.get("FLUTTER_ROOT")
    if flutter_root:
        candidate_paths.append(Path(flutter_root).expanduser().resolve() / "bin")

    flutter_home = os.environ.get("FLUTTER_HOME")
    if flutter_home:
        candidate_paths.append(Path(flutter_home).expanduser().resolve() / "bin")

    return deduplicate_paths(
        [path for path in candidate_paths if path.exists() and path.is_dir()]
    )


def deduplicate_paths(paths: list[Path]) -> list[Path]:
    unique_paths: list[Path] = []
    seen_paths: set[str] = set()

    for path in paths:
        key = str(path).lower()
        if key in seen_paths:
            continue
        seen_paths.add(key)
        unique_paths.append(path)

    return unique_paths


def build_executable_candidate_names(executable_name: str) -> list[str]:
    if os.name == "nt":
        return [
            f"{executable_name}.bat",
            f"{executable_name}.cmd",
            f"{executable_name}.exe",
            executable_name,
        ]

    return [executable_name]


def find_executable_in_directory(directory: Path, executable_name: str) -> str | None:
    for candidate_name in build_executable_candidate_names(executable_name):
        candidate_path = directory / candidate_name
        if candidate_path.exists() and candidate_path.is_file():
            return str(candidate_path)

    return None


def resolve_flutter_executable_from_path() -> str | None:
    for candidate_name in build_executable_candidate_names("flutter"):
        resolved_path = shutil.which(candidate_name)
        if resolved_path:
            return resolved_path

    return None


def resolve_dart_executable_from_path() -> str | None:
    for candidate_name in build_executable_candidate_names("dart"):
        resolved_path = shutil.which(candidate_name)
        if resolved_path:
            return resolved_path

    return None


def infer_flutter_bin_from_executable(flutter_executable: str | None) -> Path | None:
    if not flutter_executable:
        return None

    executable_path = Path(flutter_executable).expanduser().resolve()
    parent_directory = executable_path.parent

    if parent_directory.exists() and parent_directory.is_dir():
        return parent_directory

    return None


def infer_flutter_root_from_bin(flutter_bin_directory: Path | None) -> Path | None:
    if flutter_bin_directory is None:
        return None

    flutter_root = flutter_bin_directory.parent
    if flutter_root.exists() and flutter_root.is_dir():
        return flutter_root

    return None


def resolve_flutter_executable() -> tuple[str | None, Path | None]:
    flutter_from_path = resolve_flutter_executable_from_path()
    if flutter_from_path:
        flutter_bin_directory = infer_flutter_bin_from_executable(flutter_from_path)
        return flutter_from_path, flutter_bin_directory

    candidate_directories = []
    candidate_directories.extend(build_environment_flutter_bin_candidates())

    if os.name == "nt":
        candidate_directories.extend(build_windows_flutter_bin_candidates())

    for candidate_directory in deduplicate_paths(candidate_directories):
        flutter_executable = find_executable_in_directory(candidate_directory, "flutter")
        if flutter_executable:
            return flutter_executable, candidate_directory

    return None, None


def resolve_dart_executable_from_flutter_root(flutter_root: Path | None) -> str | None:
    if flutter_root is None:
        return None

    candidate_directories = [
        flutter_root / "bin",
        flutter_root / "bin" / "cache" / "dart-sdk" / "bin",
    ]

    for candidate_directory in candidate_directories:
        if not candidate_directory.exists() or not candidate_directory.is_dir():
            continue

        dart_executable = find_executable_in_directory(candidate_directory, "dart")
        if dart_executable:
            return dart_executable

    return None


def build_tool_environment(flutter_bin_directory: Path | None) -> dict[str, str]:
    environment = dict(os.environ)

    if flutter_bin_directory is None:
        return environment

    existing_path = environment.get("PATH", "")
    flutter_bin_str = str(flutter_bin_directory)

    if existing_path:
        environment["PATH"] = f"{flutter_bin_str}{os.pathsep}{existing_path}"
    else:
        environment["PATH"] = flutter_bin_str

    flutter_root = infer_flutter_root_from_bin(flutter_bin_directory)
    if flutter_root is not None:
        environment.setdefault("FLUTTER_ROOT", str(flutter_root))
        environment.setdefault("FLUTTER_HOME", str(flutter_root))

    return environment


def resolve_tooling_context() -> ToolingContext:
    flutter_executable, flutter_bin_directory = resolve_flutter_executable()
    flutter_root = infer_flutter_root_from_bin(flutter_bin_directory)
    environment = build_tool_environment(flutter_bin_directory)

    dart_executable = resolve_dart_executable_from_path()

    if dart_executable is None:
        dart_executable = resolve_dart_executable_from_flutter_root(flutter_root)

    return ToolingContext(
        flutter_executable=flutter_executable,
        dart_executable=dart_executable,
        environment=environment,
        flutter_sdk_bin=str(flutter_bin_directory) if flutter_bin_directory else None,
        flutter_root=str(flutter_root) if flutter_root else None,
    )


def run_command(
    command: list[str],
    working_directory: Path,
    environment: dict[str, str],
) -> CommandExecutionResult:
    try:
        completed_process = subprocess.run(
            command,
            cwd=working_directory,
            env=environment,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
    except FileNotFoundError:
        return CommandExecutionResult(
            command=command,
            working_directory=str(working_directory),
            exit_code=127,
            stdout="",
            stderr=f"Commande introuvable : {command[0]}",
            command_not_found=True,
        )
    except OSError as error:
        return CommandExecutionResult(
            command=command,
            working_directory=str(working_directory),
            exit_code=126,
            stdout="",
            stderr=f"Erreur système lors de l'exécution de la commande : {error}",
            command_not_found=False,
        )

    return CommandExecutionResult(
        command=command,
        working_directory=str(working_directory),
        exit_code=completed_process.returncode,
        stdout=completed_process.stdout,
        stderr=completed_process.stderr,
        command_not_found=False,
    )


def build_skipped_command_result(
    command: list[str],
    working_directory: Path,
    reason: str,
) -> CommandExecutionResult:
    return CommandExecutionResult(
        command=command,
        working_directory=str(working_directory),
        exit_code=0,
        stdout=reason,
        stderr="",
        command_not_found=False,
    )


def build_missing_tool_result(
    command: list[str],
    working_directory: Path,
    missing_tool_name: str,
    tooling_context: ToolingContext,
) -> CommandExecutionResult:
    diagnostic_lines = [
        f"Outil introuvable : {missing_tool_name}",
        f"flutter_executable résolu : {tooling_context.flutter_executable}",
        f"dart_executable résolu : {tooling_context.dart_executable}",
        f"flutter_sdk_bin résolu : {tooling_context.flutter_sdk_bin}",
        f"flutter_root résolu : {tooling_context.flutter_root}",
    ]

    return CommandExecutionResult(
        command=command,
        working_directory=str(working_directory),
        exit_code=127,
        stdout="",
        stderr="\n".join(diagnostic_lines),
        command_not_found=True,
    )


def format_written_dart_files(
    project_root: Path,
    written_files: list[WrittenFileResult],
    tooling_context: ToolingContext,
) -> tuple[list[str], CommandExecutionResult]:
    written_dart_files = [
        written_file.relative_path
        for written_file in written_files
        if written_file.is_dart_file
    ]

    if not written_dart_files:
        return (
            [],
            build_skipped_command_result(
                command=["dart", "format"],
                working_directory=project_root,
                reason="Aucun fichier Dart modifié : dart format ignoré.",
            ),
        )

    if tooling_context.dart_executable is None:
        return (
            written_dart_files,
            build_missing_tool_result(
                command=["dart", "format", *written_dart_files],
                working_directory=project_root,
                missing_tool_name="dart",
                tooling_context=tooling_context,
            ),
        )

    command = tooling_context.dart_command("format", *written_dart_files)
    result = run_command(
        command=command,
        working_directory=project_root,
        environment=tooling_context.environment,
    )
    return written_dart_files, result


def run_flutter_analyze(
    project_root: Path,
    tooling_context: ToolingContext,
) -> CommandExecutionResult:
    if tooling_context.flutter_executable is None:
        return build_missing_tool_result(
            command=["flutter", "analyze"],
            working_directory=project_root,
            missing_tool_name="flutter",
            tooling_context=tooling_context,
        )

    return run_command(
        command=tooling_context.flutter_command("analyze"),
        working_directory=project_root,
        environment=tooling_context.environment,
    )


def run_added_test_files(
    project_root: Path,
    written_files: list[WrittenFileResult],
    tooling_context: ToolingContext,
) -> tuple[list[str], list[CommandExecutionResult]]:
    added_test_files = [
        written_file.relative_path
        for written_file in written_files
        if written_file.is_added_test_file
    ]

    if not added_test_files:
        skipped_result = build_skipped_command_result(
            command=["flutter", "test"],
            working_directory=project_root,
            reason="Aucun nouveau fichier de test ajouté : flutter test ignoré.",
        )
        return [], [skipped_result]

    if tooling_context.flutter_executable is None:
        missing_tool_result = build_missing_tool_result(
            command=["flutter", "test", *added_test_files],
            working_directory=project_root,
            missing_tool_name="flutter",
            tooling_context=tooling_context,
        )
        return added_test_files, [missing_tool_result]

    test_results: list[CommandExecutionResult] = []

    for added_test_file in added_test_files:
        command = tooling_context.flutter_command("test", added_test_file)
        test_results.append(
            run_command(
                command=command,
                working_directory=project_root,
                environment=tooling_context.environment,
            )
        )

    return added_test_files, test_results


def build_command_log(command_result: CommandExecutionResult) -> str:
    command_line = shlex.join(command_result.command)

    sections = [
        f"Commande: {command_line}",
        f"Working directory: {command_result.working_directory}",
        f"Exit code: {command_result.exit_code}",
        f"Command not found: {command_result.command_not_found}",
        "",
        "===== STDOUT =====",
        command_result.stdout.rstrip(),
        "",
        "===== STDERR =====",
        command_result.stderr.rstrip(),
        "",
    ]

    return "\n".join(sections).rstrip() + "\n"


def build_tests_log(test_results: list[CommandExecutionResult]) -> str:
    log_parts: list[str] = []

    for index, test_result in enumerate(test_results, start=1):
        if index > 1:
            log_parts.append("\n" + ("-" * 80) + "\n")
        log_parts.append(build_command_log(test_result))

    return "".join(log_parts).rstrip() + "\n"


def write_text_file(file_path: Path, content: str) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(content, encoding="utf-8")


def write_json_file(file_path: Path, payload: dict[str, Any]) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def determine_final_exit_code(
    dart_format_result: CommandExecutionResult,
    flutter_analyze_result: CommandExecutionResult,
    flutter_test_results: list[CommandExecutionResult],
) -> ExitCode:
    if not dart_format_result.succeeded:
        return ExitCode.FORMAT_FAILED

    if not flutter_analyze_result.succeeded:
        return ExitCode.ANALYZE_FAILED

    for flutter_test_result in flutter_test_results:
        if not flutter_test_result.succeeded:
            return ExitCode.TESTS_FAILED

    return ExitCode.SUCCESS


def build_pipeline_report(
    project_root: Path,
    input_json_path: Path,
    output_directory: Path,
    written_files: list[WrittenFileResult],
    dart_files_formatted: list[str],
    added_test_files: list[str],
    tooling_context: ToolingContext,
    dart_format_result: CommandExecutionResult,
    flutter_analyze_result: CommandExecutionResult,
    flutter_test_results: list[CommandExecutionResult],
) -> PipelineReport:
    final_exit_code = determine_final_exit_code(
        dart_format_result=dart_format_result,
        flutter_analyze_result=flutter_analyze_result,
        flutter_test_results=flutter_test_results,
    )

    return PipelineReport(
        timestamp_utc=datetime.now(timezone.utc).isoformat(),
        project_root=str(project_root),
        input_json_path=str(input_json_path),
        output_directory=str(output_directory),
        written_files=written_files,
        dart_files_formatted=dart_files_formatted,
        added_test_files=added_test_files,
        tooling_context=tooling_context,
        dart_format_result=dart_format_result,
        flutter_analyze_result=flutter_analyze_result,
        flutter_test_results=flutter_test_results,
        final_exit_code=int(final_exit_code),
    )


def write_output_report(output_directory: Path, pipeline_report: PipelineReport) -> None:
    output_directory.mkdir(parents=True, exist_ok=True)

    write_text_file(
        output_directory / "dart_format.txt",
        build_command_log(pipeline_report.dart_format_result),
    )
    write_text_file(
        output_directory / "flutter_analyze.txt",
        build_command_log(pipeline_report.flutter_analyze_result),
    )
    write_text_file(
        output_directory / "flutter_tests.txt",
        build_tests_log(pipeline_report.flutter_test_results),
    )

    summary_payload = {
        "timestamp_utc": pipeline_report.timestamp_utc,
        "project_root": pipeline_report.project_root,
        "input_json_path": pipeline_report.input_json_path,
        "output_directory": pipeline_report.output_directory,
        "written_files": [asdict(written_file) for written_file in pipeline_report.written_files],
        "dart_files_formatted": pipeline_report.dart_files_formatted,
        "added_test_files": pipeline_report.added_test_files,
        "tooling": {
            "flutter_executable": pipeline_report.tooling_context.flutter_executable,
            "dart_executable": pipeline_report.tooling_context.dart_executable,
            "flutter_sdk_bin": pipeline_report.tooling_context.flutter_sdk_bin,
            "flutter_root": pipeline_report.tooling_context.flutter_root,
        },
        "dart_format_exit_code": pipeline_report.dart_format_result.exit_code,
        "flutter_analyze_exit_code": pipeline_report.flutter_analyze_result.exit_code,
        "flutter_test_exit_codes": [
            test_result.exit_code for test_result in pipeline_report.flutter_test_results
        ],
        "final_exit_code": pipeline_report.final_exit_code,
        "output_files": {
            "dart_format": str(output_directory / "dart_format.txt"),
            "flutter_analyze": str(output_directory / "flutter_analyze.txt"),
            "flutter_tests": str(output_directory / "flutter_tests.txt"),
            "summary": str(output_directory / "summary.json"),
        },
    }

    write_json_file(output_directory / "summary.json", summary_payload)


def run_pipeline(
    project_root: Path,
    input_json_path: Path,
    output_directory: Path,
) -> ExitCode:
    print_progress("[1/6] Résolution des outils Flutter/Dart")
    tooling_context = resolve_tooling_context()

    print_progress("[2/6] Chargement du JSON")
    patch_file_specs = load_patch_file_specs(input_json_path)

    print_progress(f"[3/6] Écriture de {len(patch_file_specs)} fichier(s)")
    written_files = write_patch_files(project_root=project_root, patch_file_specs=patch_file_specs)

    print_progress("[4/6] Formatage des fichiers Dart modifiés")
    dart_files_formatted, dart_format_result = format_written_dart_files(
        project_root=project_root,
        written_files=written_files,
        tooling_context=tooling_context,
    )

    print_progress("[5/6] Lancement de flutter analyze")
    flutter_analyze_result = run_flutter_analyze(
        project_root=project_root,
        tooling_context=tooling_context,
    )

    if flutter_analyze_result.succeeded:
        print_progress("[6/6] Lancement des nouveaux tests ajoutés")
        added_test_files, flutter_test_results = run_added_test_files(
            project_root=project_root,
            written_files=written_files,
            tooling_context=tooling_context,
        )
    else:
        print_progress("[6/6] Tests ignorés car flutter analyze a échoué")
        added_test_files = []
        flutter_test_results = [
            build_skipped_command_result(
                command=["flutter", "test"],
                working_directory=project_root,
                reason="flutter analyze a échoué : les tests ajoutés ne sont pas exécutés.",
            )
        ]

    pipeline_report = build_pipeline_report(
        project_root=project_root,
        input_json_path=input_json_path,
        output_directory=output_directory,
        written_files=written_files,
        dart_files_formatted=dart_files_formatted,
        added_test_files=added_test_files,
        tooling_context=tooling_context,
        dart_format_result=dart_format_result,
        flutter_analyze_result=flutter_analyze_result,
        flutter_test_results=flutter_test_results,
    )

    write_output_report(output_directory=output_directory, pipeline_report=pipeline_report)
    return ExitCode(pipeline_report.final_exit_code)


def main() -> int:
    try:
        arguments = parse_arguments()
        project_root = resolve_project_root(arguments.project_root)
        input_json_path = resolve_input_json_path(arguments.input_json)
        output_directory = resolve_output_directory(project_root, arguments.output_dir)

        exit_code = run_pipeline(
            project_root=project_root,
            input_json_path=input_json_path,
            output_directory=output_directory,
        )

        print(f"Pipeline terminé. Résultats disponibles dans : {output_directory}")
        return int(exit_code)

    except InputJsonError as error:
        print(f"Erreur d'entrée JSON : {error}", file=sys.stderr)
        return int(ExitCode.INPUT_ERROR)
    except UnsafeRelativePathError as error:
        print(f"Chemin refusé : {error}", file=sys.stderr)
        return int(ExitCode.INPUT_ERROR)
    except PipelineError as error:
        print(f"Erreur pipeline : {error}", file=sys.stderr)
        return int(ExitCode.FILE_WRITE_ERROR)
    except Exception as error:
        print(f"Erreur inattendue : {error}", file=sys.stderr)
        return int(ExitCode.UNEXPECTED_ERROR)


if __name__ == "__main__":
    raise SystemExit(main())