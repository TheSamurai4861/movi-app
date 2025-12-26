/// Permet d'appeler une fonction async sans attendre le résultat.
/// Utile pour les opérations en arrière-plan qui ne doivent pas bloquer.
void unawaited(Future<void> future) {
  // Ignore les erreurs potentielles
  future.catchError((_) {});
}
