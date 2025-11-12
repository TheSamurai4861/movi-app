class FirstName {
  const FirstName._(this.value);

  final String value;

  static FirstName? tryParse(String input) {
    final v = input.trim();
    if (v.isEmpty || v.length > 50) return null;
    return FirstName._(v);
  }
}
