import 'dart:async';

final class WelcomeSourceLoadingSourceResolution {
  const WelcomeSourceLoadingSourceResolution({
    required this.activeSourceIds,
    required this.showSourceSelectionAction,
    this.selectedSourceId,
    this.errorMessage,
  });

  final Set<String> activeSourceIds;
  final bool showSourceSelectionAction;
  final String? selectedSourceId;
  final String? errorMessage;

  bool get canContinue => errorMessage == null;
}

WelcomeSourceLoadingSourceResolution resolveWelcomeSourceLoadingSourceResolution({
  required Set<String> activeSourceIds,
  required Set<String> knownSourceIds,
  String? selectedSourceId,
}) {
  final normalizedActive = _normalizeWelcomeSourceIds(activeSourceIds);
  final normalizedKnown = _normalizeWelcomeSourceIds(knownSourceIds);
  final normalizedSelected = _normalizeWelcomeSourceId(selectedSourceId);

  if (normalizedActive.isNotEmpty) {
    return WelcomeSourceLoadingSourceResolution(
      activeSourceIds: normalizedActive,
      showSourceSelectionAction: false,
      selectedSourceId: normalizedSelected,
    );
  }

  if (normalizedSelected != null &&
      normalizedKnown.contains(normalizedSelected)) {
    return WelcomeSourceLoadingSourceResolution(
      activeSourceIds: <String>{normalizedSelected},
      selectedSourceId: normalizedSelected,
      showSourceSelectionAction: false,
    );
  }

  if (normalizedKnown.length == 1) {
    final restoredSourceId = normalizedKnown.first;
    return WelcomeSourceLoadingSourceResolution(
      activeSourceIds: <String>{restoredSourceId},
      selectedSourceId: restoredSourceId,
      showSourceSelectionAction: false,
    );
  }

  if (normalizedKnown.isEmpty) {
    return const WelcomeSourceLoadingSourceResolution(
      activeSourceIds: <String>{},
      showSourceSelectionAction: false,
      errorMessage:
          'Aucune source IPTV locale trouvée. Ajoutez ou reconnectez une source avant de relancer le chargement.',
    );
  }

  return const WelcomeSourceLoadingSourceResolution(
    activeSourceIds: <String>{},
    showSourceSelectionAction: true,
    errorMessage:
        "Aucune source active n'est sélectionnée. Choisissez une source avant de relancer le chargement.",
  );
}

bool shouldOfferWelcomeSourceSelectionOnFailure({
  required Set<String> knownSourceIds,
  required Set<String> activeSourceIds,
}) {
  final normalizedKnown = _normalizeWelcomeSourceIds(knownSourceIds);
  final normalizedActive = _normalizeWelcomeSourceIds(activeSourceIds);
  if (normalizedKnown.length <= 1) {
    return false;
  }
  if (normalizedActive.isEmpty) {
    return true;
  }
  return normalizedKnown.difference(normalizedActive).isNotEmpty;
}

String formatWelcomeSourceLoadingErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Le chargement de la source a expiré. Vérifiez votre connexion ou choisissez une autre source.';
  }

  final message = error.toString().replaceAll('Exception: ', '').trim();
  if (message.isEmpty) {
    return 'Le chargement de la source a échoué.';
  }
  return message;
}

Set<String> _normalizeWelcomeSourceIds(Iterable<String> ids) {
  return ids.map(_normalizeWelcomeSourceId).whereType<String>().toSet();
}

String? _normalizeWelcomeSourceId(String? sourceId) {
  final normalized = sourceId?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
