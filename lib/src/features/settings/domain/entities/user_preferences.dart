import 'package:equatable/equatable.dart';

enum ThemePreference { system, light, dark }

enum LanguagePreference { system, en, fr, es }

enum NotificationFrequency { none, importantOnly, all }

class UserPreferences extends Equatable {
  const UserPreferences({
    required this.theme,
    required this.language,
    required this.notifications,
    required this.autoplayNext,
  });

  final ThemePreference theme;
  final LanguagePreference language;
  final NotificationFrequency notifications;
  final bool autoplayNext;

  UserPreferences copyWith({
    ThemePreference? theme,
    LanguagePreference? language,
    NotificationFrequency? notifications,
    bool? autoplayNext,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      autoplayNext: autoplayNext ?? this.autoplayNext,
    );
  }

  @override
  List<Object?> get props => [theme, language, notifications, autoplayNext];
}
