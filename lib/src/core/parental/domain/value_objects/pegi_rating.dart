import 'package:equatable/equatable.dart';

/// PEGI rating supported by the app.
///
/// Allowed values: 3, 7, 12, 16, 18
class PegiRating extends Equatable {
  const PegiRating._(this.value);

  final int value;

  static const PegiRating pegi3 = PegiRating._(3);
  static const PegiRating pegi7 = PegiRating._(7);
  static const PegiRating pegi12 = PegiRating._(12);
  static const PegiRating pegi16 = PegiRating._(16);
  static const PegiRating pegi18 = PegiRating._(18);

  static const List<PegiRating> all = <PegiRating>[
    pegi3,
    pegi7,
    pegi12,
    pegi16,
    pegi18,
  ];

  static PegiRating? tryParse(int? value) {
    if (value == null) return null;
    return all.cast<PegiRating?>().firstWhere(
          (p) => p!.value == value,
          orElse: () => null,
        );
  }

  /// Convert a "minimum age" (ex: 13) to the nearest PEGI bucket above.
  ///
  /// Mapping:
  /// - 0–3  -> 3
  /// - 4–7  -> 7
  /// - 8–12 -> 12
  /// - 13–16 -> 16
  /// - 17+ -> 18
  static PegiRating snapFromMinAge(int minAge) {
    if (minAge <= 3) return pegi3;
    if (minAge <= 7) return pegi7;
    if (minAge <= 12) return pegi12;
    if (minAge <= 16) return pegi16;
    return pegi18;
  }

  bool allows(PegiRating required) => value >= required.value;

  @override
  List<Object?> get props => <Object?>[value];

  @override
  String toString() => 'PEGI $value';
}

