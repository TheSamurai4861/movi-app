#!/usr/bin/env bash
set -euo pipefail
python scripts/verify_codex_workflow.py
python scripts/check_workflow_state.py
