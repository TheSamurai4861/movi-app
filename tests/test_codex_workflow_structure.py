from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class CodexWorkflowStructureTest(unittest.TestCase):
    def test_required_agent_files_exist(self) -> None:
        agent_names = ['planner', 'implementer', 'reviewer', 'safety']
        for agent_name in agent_names:
            path = ROOT / '.codex' / 'agents' / f'{agent_name}.toml'
            self.assertTrue(path.exists(), f'Missing agent file: {path}')

    def test_required_skill_files_exist(self) -> None:
        for skill_name in ['nasa-plan', 'nasa-implement', 'nasa-review', 'nasa-release-gate', 'nasa-handoff']:
            path = ROOT / '.codex' / 'skills' / skill_name / 'SKILL.md'
            self.assertTrue(path.exists(), f'Missing skill file: {path}')

    def test_requirement_files_exist(self) -> None:
        requirement_ids = [f'REQ-CODEX-00{i}' for i in range(1, 10)]
        for requirement_id in requirement_ids:
            path = ROOT / 'docs' / 'requirements' / f'{requirement_id}.md'
            self.assertTrue(path.exists(), f'Missing requirement file: {path}')

    def test_config_contains_expected_sandbox_controls(self) -> None:
        config = (ROOT / '.codex' / 'config.toml').read_text(encoding='utf-8')
        self.assertIn('approval_policy = "on-request"', config)
        self.assertIn('sandbox_mode = "workspace-write"', config)
        self.assertIn('web_search = false', config)
        self.assertIn('nasa-handoff', config)

    def test_traceability_references_all_requirements(self) -> None:
        traceability = (ROOT / 'docs' / 'traceability.md').read_text(encoding='utf-8')
        for requirement_id in [f'REQ-CODEX-00{i}' for i in range(1, 10)]:
            self.assertIn(requirement_id, traceability)
        self.assertIn('ADR-0001', traceability)

    def test_verification_evidence_files_exist(self) -> None:
        for rel in [
            'docs/verification/current-change.md',
            'docs/verification/reviewer-evidence.md',
            'docs/verification/ci-evidence.md',
            'docs/verification/workflow-audit-log.md',
            'docs/deviations/README.md',
        ]:
            self.assertTrue((ROOT / rel).exists(), f'Missing evidence file: {rel}')

    def test_workflow_state_is_machine_readable(self) -> None:
        state = json.loads((ROOT / '.codex' / 'workflow' / 'state.json').read_text(encoding='utf-8'))
        self.assertEqual(state['current_stage'], 'PLANNED')
        self.assertEqual(state['current_agent'], 'planner')
        self.assertEqual(state['status'], 'DONE')
        self.assertEqual(state['next_agent'], 'implementer')
        self.assertIn('reviewer_evidence', state['evidence'])
        self.assertIn('ci_evidence', state['evidence'])

    def test_entry_exit_criteria_define_all_roles(self) -> None:
        criteria = (ROOT / '.codex' / 'workflow' / 'entry_exit_criteria.md').read_text(encoding='utf-8')
        for marker in ['## Planner', '## Implementer', '## Reviewer', '## Safety']:
            self.assertIn(marker, criteria)
        self.assertIn('Adaptive requirements', criteria)


if __name__ == '__main__':
    unittest.main()
