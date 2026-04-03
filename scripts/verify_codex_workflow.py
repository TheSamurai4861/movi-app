from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_PATHS = [
    ROOT / 'AGENTS.md',
    ROOT / '.codex' / 'config.toml',
    ROOT / '.codex' / 'agents' / 'planner.toml',
    ROOT / '.codex' / 'agents' / 'implementer.toml',
    ROOT / '.codex' / 'agents' / 'reviewer.toml',
    ROOT / '.codex' / 'agents' / 'safety.toml',
    ROOT / '.codex' / 'skills' / 'nasa-plan' / 'SKILL.md',
    ROOT / '.codex' / 'skills' / 'nasa-implement' / 'SKILL.md',
    ROOT / '.codex' / 'skills' / 'nasa-review' / 'SKILL.md',
    ROOT / '.codex' / 'skills' / 'nasa-release-gate' / 'SKILL.md',
    ROOT / '.codex' / 'skills' / 'nasa-handoff' / 'SKILL.md',
    ROOT / '.codex' / 'workflow' / 'state.json',
    ROOT / '.codex' / 'workflow' / 'state.schema.json',
    ROOT / '.codex' / 'workflow' / 'entry_exit_criteria.md',
    ROOT / '.github' / 'workflows' / 'ci.yml',
    ROOT / '.github' / 'workflows' / 'quality-gate.yml',
    ROOT / '.github' / 'PULL_REQUEST_TEMPLATE.md',
    ROOT / 'docs' / 'README_refactor.md',
    ROOT / 'docs' / 'architecture_decisions.md',
    ROOT / 'docs' / 'risk_assessment.md',
    ROOT / 'docs' / 'test_strategy.md',
    ROOT / 'docs' / 'traceability.md',
    ROOT / 'docs' / 'workflow_state.md',
    ROOT / 'docs' / 'changelog.md',
    ROOT / 'docs' / 'rollback.md',
    ROOT / 'docs' / 'sbom_inventory.md',
    ROOT / 'docs' / 'operations' / 'runbook.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-001.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-002.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-003.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-004.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-005.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-006.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-007.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-008.md',
    ROOT / 'docs' / 'requirements' / 'REQ-CODEX-009.md',
    ROOT / 'docs' / 'verification' / 'current-change.md',
    ROOT / 'docs' / 'verification' / 'reviewer-evidence.md',
    ROOT / 'docs' / 'verification' / 'ci-evidence.md',
    ROOT / 'docs' / 'verification' / 'workflow-audit-log.md',
    ROOT / 'docs' / 'deviations' / 'README.md',
    ROOT / 'scripts' / 'check_workflow_state.py',
    ROOT / 'DELIVERY_MANIFEST.md',
]

REQUIRED_MARKERS = {
    ROOT / '.codex' / 'config.toml': ['approval_policy = "on-request"', 'sandbox_mode = "workspace-write"', 'nasa-handoff'],
    ROOT / 'AGENTS.md': ['Never modify code before producing', 'Safety gate must block completion', 'state record', 'next role'],
    ROOT / 'docs' / 'traceability.md': ['REQ-CODEX-001', 'REQ-CODEX-002', 'REQ-CODEX-003', 'REQ-CODEX-004', 'REQ-CODEX-005', 'REQ-CODEX-006', 'REQ-CODEX-007', 'REQ-CODEX-008', 'REQ-CODEX-009'],
    ROOT / 'docs' / 'workflow_state.md': ['single source of truth', 'CURRENT_STAGE', 'NEXT_AGENT'],
    ROOT / 'docs' / 'verification' / 'current-change.md': ['Requirement ID:'],
    ROOT / 'docs' / 'verification' / 'reviewer-evidence.md': ['Reviewer:'],
    ROOT / 'docs' / 'verification' / 'ci-evidence.md': ['Status:'],
    ROOT / 'docs' / 'verification' / 'workflow-audit-log.md': ['Stage', 'Agent', 'Status', 'Next agent'],
}


def main() -> int:
    missing = [str(path.relative_to(ROOT)) for path in REQUIRED_PATHS if not path.exists()]
    if missing:
        print('Missing required paths:')
        for item in missing:
            print(f'- {item}')
        return 1

    for path, markers in REQUIRED_MARKERS.items():
        content = path.read_text(encoding='utf-8')
        for marker in markers:
            if marker not in content:
                print(f'Marker missing in {path.relative_to(ROOT)}: {marker}')
                return 1

    print('Codex workflow structure verification: PASS')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
