class AppMetadata {
  const AppMetadata({
    required this.version,
    required this.buildNumber,
    this.supportEmail = 'support@movi.app',
  });

  final String version;
  final String buildNumber;
  final String supportEmail;

  AppMetadata copyWith({
    String? version,
    String? buildNumber,
    String? supportEmail,
  }) {
    return AppMetadata(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      supportEmail: supportEmail ?? this.supportEmail,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppMetadata) return false;
    return version == other.version &&
        buildNumber == other.buildNumber &&
        supportEmail == other.supportEmail;
  }

  @override
  int get hashCode => Object.hash(version, buildNumber, supportEmail);
}
