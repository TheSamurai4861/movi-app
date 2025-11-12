import 'package:equatable/equatable.dart';

class XtreamCatalogSnapshot extends Equatable {
  const XtreamCatalogSnapshot({
    required this.accountId,
    required this.lastSyncAt,
    required this.movieCount,
    required this.seriesCount,
    this.lastError,
  });

  final String accountId;
  final DateTime lastSyncAt;
  final int movieCount;
  final int seriesCount;
  final String? lastError;

  XtreamCatalogSnapshot copyWith({
    DateTime? lastSyncAt,
    int? movieCount,
    int? seriesCount,
    String? lastError,
  }) {
    return XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      movieCount: movieCount ?? this.movieCount,
      seriesCount: seriesCount ?? this.seriesCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
    accountId,
    lastSyncAt,
    movieCount,
    seriesCount,
    lastError,
  ];
}
