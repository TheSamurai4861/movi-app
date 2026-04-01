# Bootstrap V2 rollout safe

## Objectif
Déployer le bootstrap robuste sans régression UX sur les profils existants.

## Etape 1 - Shadow mode (dev)
- Garder le comportement utilisateur actuel.
- Activer uniquement les logs structurés V2 (runId, phase, result, errorCode).
- Mesurer:
  - taux de preload réussi,
  - temps moyen `auth -> home`,
  - fréquence des retries IPTV.

## Etape 2 - Feature flag interne
- Activer le flux V2 pour les builds internes via flag.
- Vérifier:
  - pas de `home` partiel,
  - pas de blocage bootstrap > timeout global,
  - cohérence des messages de recovery.

## Etape 3 - Progressive rollout
- Activation par paliers (10% -> 50% -> 100%).
- Gate de progression:
  - crash-free stable,
  - erreurs `iptv_empty_data` sous seuil défini,
  - pas d'augmentation des abandons au lancement.

## Etape 4 - Stabilisation
- Retirer les anciens chemins de fallback devenus obsolètes.
- Conserver les métriques V2 en monitoring permanent.

## Checklist de validation
- [ ] Lancement local sans session (mode local) valide.
- [ ] Lancement cloud avec source restaurée valide.
- [ ] Lancement cloud avec source invalide redirige vers choix source.
- [ ] Timeout IPTV déclenche fallback/retry attendu.
- [ ] Guard route bloque `home` tant que readiness incomplet.
