import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class ContentReport extends Equatable {
  const ContentReport({
    required this.accountId,
    required this.contentType,
    required this.tmdbId,
    required this.reportType,
    this.profileId,
    this.contentTitle,
    this.message,
    this.profilePegiLimit,
    this.requiredPegi,
    this.minAge,
    this.regionUsed,
    this.rawRating,
    this.decisionReason,
  });

  final String accountId;
  final String? profileId;
  final ContentType contentType;
  final int tmdbId;
  final String reportType;
  final String? contentTitle;
  final String? message;

  final int? profilePegiLimit;
  final int? requiredPegi;
  final int? minAge;
  final String? regionUsed;
  final String? rawRating;
  final String? decisionReason;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'account_id': accountId,
    'profile_id': profileId,
    'content_type': contentType == ContentType.movie ? 'movie' : 'series',
    'tmdb_id': tmdbId,
    'content_title': contentTitle,
    'report_type': reportType,
    'message': message,
    'profile_pegi_limit': profilePegiLimit,
    'required_pegi': requiredPegi,
    'min_age': minAge,
    'region_used': regionUsed,
    'raw_rating': rawRating,
    'decision_reason': decisionReason,
  };

  @override
  List<Object?> get props => <Object?>[
    accountId,
    profileId,
    contentType,
    tmdbId,
    reportType,
    contentTitle,
    message,
    profilePegiLimit,
    requiredPegi,
    minAge,
    regionUsed,
    rawRating,
    decisionReason,
  ];
}

