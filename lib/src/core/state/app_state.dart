import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppState extends Equatable {
  const AppState({
    this.themeMode = ThemeMode.system,
    this.isOnline = true,
    this.preferredLocale = 'en-US',
    this.activeIptvSources = const <String>{},
  });

  final ThemeMode themeMode;
  final bool isOnline;
  final String preferredLocale;
  final Set<String> activeIptvSources;

  AppState copyWith({
    ThemeMode? themeMode,
    bool? isOnline,
    String? preferredLocale,
    Set<String>? activeIptvSources,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      isOnline: isOnline ?? this.isOnline,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      activeIptvSources: activeIptvSources ?? this.activeIptvSources,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    isOnline,
    preferredLocale,
    activeIptvSources,
  ];
}
