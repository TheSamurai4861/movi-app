import 'package:equatable/equatable.dart';

enum MovieVariantMatchKind { strict, compatible, none }

enum MovieVariantMatchReason {
  sameStreamId,
  sameTmdbId,
  sameCleanTitleAndYear,
  sameCleanTitleWithMissingYear,
  sameCleanTitleWithoutYear,
  contentTypeMismatch,
  conflictingTmdbId,
  cleanTitleMissing,
  cleanTitleMismatch,
  conflictingYear,
}

class MovieVariantMatchResult extends Equatable {
  const MovieVariantMatchResult({
    required this.kind,
    required this.reason,
    required this.referenceTitle,
    required this.candidateTitle,
    required this.referenceYear,
    required this.candidateYear,
  });

  final MovieVariantMatchKind kind;
  final MovieVariantMatchReason reason;
  final String referenceTitle;
  final String candidateTitle;
  final int? referenceYear;
  final int? candidateYear;

  bool get isMatch => kind != MovieVariantMatchKind.none;
  bool get isStrict => kind == MovieVariantMatchKind.strict;
  bool get isCompatible => kind == MovieVariantMatchKind.compatible;

  @override
  List<Object?> get props => <Object?>[
    kind,
    reason,
    referenceTitle,
    candidateTitle,
    referenceYear,
    candidateYear,
  ];
}
