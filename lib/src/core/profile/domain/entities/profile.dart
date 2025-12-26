/// Entity mÃƒÂ©tier "profil" (Netflix-like).
///
/// - Ne dÃƒÂ©pend d'aucun backend (Supabase/JSON).
/// - Pas de fromJson/toJson ici (clean architecture).
/// - Value-like : ÃƒÂ©galitÃƒÂ© + hashCode pour faciliter tests, diff UI, etc.
class Profile {
  const Profile({
    required this.id,
    required this.accountId,
    required this.name,
    required this.color,
    this.avatarUrl,
    this.createdAt,
    this.isKid = false,
    this.pegiLimit,
    this.hasPin = false,
  });

  final String id;
  final String accountId;
  final String name;
  final int color; // ARGB ex: 0xFF2160AB
  final String? avatarUrl;
  final DateTime? createdAt;

  /// Parental controls (optional).
  final bool isKid;
  final int? pegiLimit; // 3/7/12/16/18 (null = unrestricted)
  final bool hasPin;

  Profile copyWith({
    String? id,
    String? accountId,
    String? name,
    int? color,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isKid,
    int? pegiLimit,
    bool? hasPin,
  }) {
    return Profile(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      color: color ?? this.color,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isKid: isKid ?? this.isKid,
      pegiLimit: pegiLimit ?? this.pegiLimit,
      hasPin: hasPin ?? this.hasPin,
    );
  }

  @override
  String toString() {
    return 'Profile('
        'id=$id, '
        'accountId=$accountId, '
        'name=$name, '
        'color=$color, '
        'avatarUrl=$avatarUrl, '
        'createdAt=$createdAt, '
        'isKid=$isKid, '
        'pegiLimit=$pegiLimit, '
        'hasPin=$hasPin'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Profile &&
            other.id == id &&
            other.accountId == accountId &&
            other.name == name &&
            other.color == color &&
            other.avatarUrl == avatarUrl &&
            other.createdAt == createdAt &&
            other.isKid == isKid &&
            other.pegiLimit == pegiLimit &&
            other.hasPin == hasPin);
  }

  @override
  int get hashCode => Object.hash(
        id,
        accountId,
        name,
        color,
        avatarUrl,
        createdAt,
        isKid,
        pegiLimit,
        hasPin,
      );
}
