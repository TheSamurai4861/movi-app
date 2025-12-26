class StalkerStreamDto {
  StalkerStreamDto({
    required this.streamId,
    required this.name,
    required this.streamType,
    required this.categoryId,
    this.streamIcon,
    this.plot,
    this.released,
    this.year,
    this.tmdbId,
    this.rating,
    this.director,
    this.actors,
  });

  factory StalkerStreamDto.fromJson(Map<String, dynamic> json) {
    // Parse stream ID (peut être string ou int, parfois avec format "id:id")
    dynamic streamIdRaw = json['id'] ?? json['stream_id'];
    int streamId = 0;
    
    if (streamIdRaw is int) {
      streamId = streamIdRaw;
    } else if (streamIdRaw is num) {
      streamId = streamIdRaw.toInt();
    } else if (streamIdRaw is String) {
      // Gérer le format "225171:225171" pour les séries
      final parts = streamIdRaw.split(':');
      final firstPart = int.tryParse(parts[0]);
      if (firstPart != null) {
        streamId = firstPart;
      }
    }

    // Parse TMDB ID
    dynamic tmdbRaw = json['tmdb_id'] ?? json['tmdb'] ?? json['tmdbId'];
    int? tmdbParsed;
    if (tmdbRaw is num) {
      tmdbParsed = tmdbRaw.toInt();
    } else if (tmdbRaw is String) {
      tmdbParsed = int.tryParse(tmdbRaw);
    }

    // Parse year (peut être dans "year" ou extrait de "added" ou autre)
    int? yearParsed;
    final yearRaw = json['year'];
    if (yearRaw is num) {
      yearParsed = yearRaw.toInt();
    } else if (yearRaw is String) {
      // Peut être au format "06/11/2025" ou juste l'année
      final parts = yearRaw.split('/');
      if (parts.length >= 3) {
        yearParsed = int.tryParse(parts[2]);
      } else {
        yearParsed = int.tryParse(yearRaw.trim());
      }
    }

    // Parse released date
    final released = json['added']?.toString() ?? 
                    json['released']?.toString() ?? 
                    json['release_date']?.toString();

    // Parse rating
    double? rating;
    final ratingRaw = json['rating_imdb'] ?? json['rating'] ?? json['rating_kinopoisk'];
    if (ratingRaw != null) {
      if (ratingRaw is num) {
        rating = ratingRaw.toDouble();
      } else if (ratingRaw is String) {
        rating = double.tryParse(ratingRaw);
      }
    }

    // Parse category ID
    final categoryId = json['category_id']?.toString() ?? 
                      json['cat_genre_id_1']?.toString() ?? 
                      '';

    // Parse stream type (vod ou series)
    final streamType = json['is_series'] == 1 || json['is_series'] == true
        ? 'series'
        : (json['is_movie'] == 1 || json['is_movie'] == true ? 'movie' : 'vod');

    return StalkerStreamDto(
      streamId: streamId,
      name: json['name']?.toString() ?? 
            json['title']?.toString() ?? 
            json['o_name']?.toString() ?? 
            'Untitled',
      streamType: streamType,
      categoryId: categoryId,
      streamIcon: json['screenshot_uri']?.toString() ?? 
                  json['pic']?.toString() ?? 
                  json['cover']?.toString(),
      plot: json['description']?.toString() ?? json['plot']?.toString(),
      released: released,
      year: yearParsed,
      tmdbId: tmdbParsed,
      rating: rating,
      director: json['director']?.toString(),
      actors: json['actors']?.toString(),
    );
  }

  final int streamId;
  final String name;
  final String streamType;
  final String categoryId;
  final String? streamIcon;
  final String? plot;
  final String? released;
  final int? year;
  final int? tmdbId;
  final double? rating;
  final String? director;
  final String? actors;
}

