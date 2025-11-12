// ignore_for_file: public_member_api_docs

import 'package:equatable/equatable.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

enum ContentType { movie, series, saga, playlist, person }

/// Référence légère et immuable vers un contenu affichable.
class ContentReference extends Equatable {
  const ContentReference({
    required this.id,
    required this.title,
    required this.type,
    this.poster,
    this.year,
    this.rating,
  });

  final String id;
  final MediaTitle title;
  final ContentType type;
  final Uri? poster;
  final int? year;
  final double? rating;

  bool get hasPoster => poster != null;

  /// CopyWith immuable.
  ///
  /// Utilise `Optional<T>` pour distinguer :
  /// - `null`   → ne pas modifier
  /// - `Optional.of(null)` → setter null
  /// - `Optional.of(v)`    → setter v
  ContentReference copyWith({
    String? id,
    MediaTitle? title,
    ContentType? type,
    Optional<Uri?>? poster,
    Optional<int?>? year,
    Optional<double?>? rating,
  }) {
    return ContentReference(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      poster: poster == null ? this.poster : poster.value,
      year: year == null ? this.year : year.value,
      rating: rating == null ? this.rating : rating.value,
    );
  }

  @override
  String toString() =>
      'ContentReference('
      'id: $id, '
      'title: ${title.value}, '
      'type: $type, '
      'poster: ${poster?.toString() ?? "-"}, '
      'year: ${year ?? "-"}, '
      'rating: ${rating ?? "-"}'
      ')';

  @override
  List<Object?> get props => <Object?>[id, title, type, poster, year, rating];
}

/// Wrapper permettant de distinguer
/// - "ne pas modifier"  → paramètre copyWith = null
/// - "modifier à valeur X (y compris null)" → Optional.of(...)
class Optional<T> {
  const Optional._(this.value);

  final T value;

  /// Définit une valeur explicite
  static Optional<T> of<T>(T v) => Optional<T>._(v);

  /// Crée un Optional(null)
  static Optional<T?> absent<T>() => Optional<T?>._(null);
}
