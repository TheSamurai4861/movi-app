class CloudSelectedProfileIdSanitizer {
  const CloudSelectedProfileIdSanitizer();

  static final RegExp _cloudProfileIdPattern = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-'
    r'[0-9a-fA-F]{12}$',
  );

  String? sanitize(String? profileId) {
    final trimmed = profileId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (!_cloudProfileIdPattern.hasMatch(trimmed)) return null;
    return trimmed;
  }
}
