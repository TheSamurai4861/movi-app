from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
STATE_PATH = ROOT / '.codex' / 'workflow' / 'state.json'
AUDIT_LOG_PATH = ROOT / 'docs' / 'verification' / 'workflow-audit-log.md'
CRITERIA_PATH = ROOT / '.codex' / 'workflow' / 'entry_exit_criteria.md'

ALLOWED = {
    'PLANNED': {'agent': 'planner', 'done_next': 'implementer', 'blocked_next': 'planner'},
    'APPROVED_FOR_IMPLEMENTATION': {'agent': 'implementer', 'done_next': 'reviewer', 'blocked_next': 'planner'},
    'IMPLEMENTED': {'agent': 'reviewer', 'done_next': 'safety', 'blocked_next': 'implementer'},
    'REVIEW_BLOCKED': {'agent': 'implementer', 'done_next': 'reviewer', 'blocked_next': 'planner'},
    'READY_FOR_SAFETY': {'agent': 'safety', 'done_next': 'none', 'blocked_next': 'implementer'},
    'MERGE_READY': {'agent': 'safety', 'done_next': 'none', 'blocked_next': 'none'},
    'REJECTED': {'agent': 'safety', 'done_next': 'planner', 'blocked_next': 'planner'},
}


def fail(message: str) -> int:
    print(message)
    return 1


def main() -> int:
    if not STATE_PATH.exists():
        return fail('Missing workflow state file.')
    if not AUDIT_LOG_PATH.exists():
        return fail('Missing workflow audit log.')
    if not CRITERIA_PATH.exists():
        return fail('Missing entry/exit criteria file.')

    state = json.loads(STATE_PATH.read_text(encoding='utf-8'))
    required_keys = {
        'workflow_id', 'current_stage', 'current_agent', 'status', 'next_agent',
        'allowed_next_agents', 'change_criticality', 'component_class',
        'requirement_ids', 'evidence', 'blockers', 'last_updated'
    }
    missing = required_keys - set(state)
    if missing:
        return fail(f'Missing state keys: {sorted(missing)}')

    stage = state['current_stage']
    if stage not in ALLOWED:
        return fail(f'Invalid current stage: {stage}')

    allowed = ALLOWED[stage]
    if state['current_agent'] != allowed['agent']:
        return fail(f"Invalid current agent for stage {stage}: {state['current_agent']}")

    status = state['status']
    if status not in {'DONE', 'BLOCKED'}:
        return fail(f'Invalid status: {status}')

    expected_next = allowed['done_next'] if status == 'DONE' else allowed['blocked_next']
    next_agent = state['next_agent']
    if next_agent != expected_next:
        return fail(f'Invalid next agent for stage {stage} with status {status}: expected {expected_next}, got {next_agent}')

    if next_agent not in state['allowed_next_agents']:
        return fail(f'Next agent {next_agent} missing from allowed_next_agents')

    evidence = state['evidence']
    for marker in ['traceability', 'tests', 'static_analysis', 'reviewer_evidence', 'ci_evidence', 'rollback']:
        if marker not in evidence:
            return fail(f'Missing evidence marker: {marker}')

    criticality = state['change_criticality']
    component_class = state['component_class']
    is_sensitive = criticality in {'C1', 'C2'} or component_class == 'L1'
    if is_sensitive and not state.get('independent_review_required', False):
        return fail('Sensitive change must require independent review.')

    audit_log = AUDIT_LOG_PATH.read_text(encoding='utf-8')
    for marker in ['Date', 'Stage', 'Agent', 'Status', 'Next agent']:
        if marker not in audit_log:
            return fail(f'Missing audit log marker: {marker}')

    print('Workflow state verification: PASS')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
