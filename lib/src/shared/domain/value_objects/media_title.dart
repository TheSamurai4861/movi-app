class MediaTitle {
  MediaTitle(String value) : value = value.trim();

  final String value;

  String get display => value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MediaTitle && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
