#!/usr/bin/env bash
set -euo pipefail
required_files=(
  "docs/traceability.md"
  "docs/risk_assessment.md"
  "docs/rollback.md"
  "docs/test_strategy.md"
  "docs/workflow_state.md"
  ".codex/workflow/state.json"
  ".codex/workflow/state.schema.json"
  ".codex/workflow/entry_exit_criteria.md"
  "docs/verification/current-change.md"
  "docs/verification/reviewer-evidence.md"
  "docs/verification/ci-evidence.md"
  "docs/verification/workflow-audit-log.md"
  "docs/deviations/README.md"
  ".github/PULL_REQUEST_TEMPLATE.md"
)

for path in "${required_files[@]}"; do
  if [ ! -f "$path" ]; then
    echo "Missing required traceability artifact: $path"
    exit 1
  fi
done

for req in REQ-CODEX-001 REQ-CODEX-002 REQ-CODEX-003 REQ-CODEX-004 REQ-CODEX-005 REQ-CODEX-006 REQ-CODEX-007 REQ-CODEX-008 REQ-CODEX-009; do
  grep -q "$req" docs/traceability.md
  test -f "docs/requirements/${req}.md"
done

grep -q "Requirement ID:" docs/verification/current-change.md
grep -q "Reviewer:" docs/verification/reviewer-evidence.md
grep -q "Status:" docs/verification/ci-evidence.md
grep -q "NEXT_AGENT" .codex/workflow/entry_exit_criteria.md || grep -q "Next agent" .codex/workflow/entry_exit_criteria.md
python scripts/check_workflow_state.py
