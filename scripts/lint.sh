#!/usr/bin/env bash
set -euo pipefail
python -m py_compile tests/test_codex_workflow_structure.py scripts/verify_codex_workflow.py
