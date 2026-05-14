/// Permet d'appeler une fonction async sans attendre le résultat.
/// Utile pour les opérations en arrière-plan qui ne doivent pas bloquer.
void unawaited<T>(Future<T> future) {
  // Ignore les erreurs potentielles
  future.then<void>((_) {}, onError: (Object _, StackTrace __) {});
}
