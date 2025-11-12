// lib/src/features/category_browser/domain/value_objects/category_key.dart
import 'package:equatable/equatable.dart';

/// Clé de catégorie visible au format `<alias>/<categoryTitle>`.
class CategoryKey extends Equatable {
  const CategoryKey({required this.alias, required this.title});

  final String alias;
  final String title;

  /// Parse une clé visible (ex: "premium-ott.com/Action").
  factory CategoryKey.parse(String raw) {
    final idx = raw.indexOf('/');
    if (idx >= 0 && idx < raw.length - 1) {
      final alias = raw.substring(0, idx);
      final title = raw.substring(idx + 1);
      return CategoryKey(alias: alias, title: title);
    }
    return CategoryKey(alias: raw, title: raw);
  }

  @override
  List<Object?> get props => [alias, title];
}