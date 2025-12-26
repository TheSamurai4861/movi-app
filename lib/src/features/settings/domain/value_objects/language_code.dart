class LanguageCode {
  const LanguageCode._(this.value);

  final String value;

  static LanguageCode? tryParse(String input) {
    final v = input.trim().toLowerCase();
    if (v.isEmpty || v.length > 10) return null;
    return LanguageCode._(v);
  }
}
