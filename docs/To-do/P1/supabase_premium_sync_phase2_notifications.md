# Phase 2 (optionnel) — Notifications serveur abonnement

Ce document décrit l’implémentation “hors-app” recommandée pour garder le statut Premium à jour même quand l’utilisateur n’ouvre pas Movi.

## Apple — App Store Server Notifications

- **But**: recevoir des webhooks (renouvellement, expiration, remboursement, révocation).
- **Approche**:
  - Exposer un endpoint (Edge Function ou serveur) recevant les notifications.
  - Vérifier la signature (JWS) Apple.
  - Mettre à jour `subscription_entitlements` (status/expires_at/last_verified_at).
- **Données à stocker**:
  - L’identifiant de transaction/original transaction id associé à `user_id`.

## Google — Real-time Developer Notifications (RTDN)

- **But**: Pub/Sub push quand l’état de souscription change.
- **Approche**:
  - Créer un topic Pub/Sub + subscription push vers un endpoint (Edge Function ou serveur).
  - Valider le message, extraire `purchaseToken` / `subscriptionId`.
  - Re-vérifier via Google Play Developer API puis mettre à jour `subscription_entitlements`.

## Notes

- Préférer une Edge Function dédiée (ex: `subscription_webhooks`) avec **service role**.
- Ne jamais logger des tokens/receipts en clair.

