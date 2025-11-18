/// Représente une source vidéo à lire
class VideoSource {
  const VideoSource({
    required this.url,
    this.title,
    this.subtitle,
  });

  /// URL de la vidéo (peut être locale ou distante)
  final String url;

  /// Titre de la vidéo (optionnel)
  final String? title;

  /// Sous-titre/description (optionnel)
  final String? subtitle;
}

