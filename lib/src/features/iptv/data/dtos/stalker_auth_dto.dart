class StalkerAuthDto {
  StalkerAuthDto({
    required this.token,
    required this.isAuthorized,
    this.expiration,
    this.message,
  });

  factory StalkerAuthDto.fromHandshakeJson(Map<String, dynamic> json) {
    // La réponse Stalker est souvent dans un objet "js"
    final jsData = json['js'] ?? json;
    final token = jsData['token']?.toString() ?? '';
    
    return StalkerAuthDto(
      token: token,
      isAuthorized: token.isNotEmpty,
      message: token.isNotEmpty ? null : 'Token non obtenu',
    );
  }

  factory StalkerAuthDto.fromProfileJson(Map<String, dynamic> json) {
    // Le profil peut contenir des infos d'expiration
    final jsData = json['js'] ?? json;
    
    // Le profil ne contient pas de token (il vient du handshake)
    // On vérifie plutôt si le profil contient des données valides
    final hasValidProfile = jsData.isNotEmpty && 
                           jsData['id'] != null;
    
    // Parse expiration si disponible (format peut varier)
    DateTime? expiration;
    final expDate = jsData['expire_billing_date'] ?? jsData['expires_at'];
    if (expDate != null) {
      if (expDate is String && expDate.isNotEmpty && expDate != '0000-00-00 00:00:00') {
        expiration = DateTime.tryParse(expDate);
      }
    }
    
    return StalkerAuthDto(
      token: '', // Le token n'est pas dans le profil
      isAuthorized: hasValidProfile,
      expiration: expiration,
      message: hasValidProfile ? null : 'Profil invalide ou vide',
    );
  }

  final String token;
  final bool isAuthorized;
  final DateTime? expiration;
  final String? message;
}

