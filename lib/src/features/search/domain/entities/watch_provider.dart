import 'package:equatable/equatable.dart';

class WatchProvider extends Equatable {
  const WatchProvider({
    required this.providerId,
    required this.providerName,
    this.logoPath,
    this.displayPriority,
  });

  final int providerId;
  final String providerName;
  final String? logoPath;
  final int? displayPriority;

  @override
  List<Object?> get props => [providerId, providerName, logoPath, displayPriority];
}
