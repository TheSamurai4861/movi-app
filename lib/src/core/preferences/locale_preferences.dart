class LocalePreferences {
  LocalePreferences({String defaultLanguageCode = 'en-US'})
      : _languageCode = defaultLanguageCode;

  String _languageCode;

  String get languageCode => _languageCode;

  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
  }
}
