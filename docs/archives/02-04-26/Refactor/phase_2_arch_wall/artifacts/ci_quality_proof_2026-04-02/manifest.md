# Manifest — preuves CI Codemagic — `ci-quality-proof` — 2026-04-02

## Objet
Archive audit-able des artefacts exportés depuis Codemagic pour démontrer la **gate de sortie Phase 2** :
« aucun nouveau code ne peut réintroduire une violation bloquante » (mur baseline + canary).

## Métadonnées (à compléter)
- **Date (UTC)** : `2026-04-02`
- **Branche** : `main`
- **Commit** : `d81c2bac23c6f68bd14d7cee6ce7aa931fffe5e7`
- **Workflow** : `ci-quality-proof`
- **Build ID** : `69ce40d6a3d6429948fed242`
- **Run URL** : `<à compléter>`

## Fichiers attendus (ci_proofs)
- `metadata.txt`
- `arch_lint.log`
- `arch_violations_delta.md`
- `arch_canary_report.md`
- `arch_canary.log`

## Notes
- Ces fichiers doivent être téléchargés depuis l’onglet **Artifacts** de l’exécution Codemagic, puis déposés dans ce même dossier.
- Ne pas inclure de secrets dans les logs/rapports.

