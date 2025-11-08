class MediaTitle {
  MediaTitle(String value)
      : value = value.trim();

  final String value;

  String get display => value;

  @override
  String toString() => value;
}
