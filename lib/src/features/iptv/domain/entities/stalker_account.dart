import 'package:equatable/equatable.dart';

import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';

enum StalkerAccountStatus { pending, active, expired, error }

class StalkerAccount extends Equatable {
  const StalkerAccount({
    required this.id,
    required this.alias,
    required this.endpoint,
    required this.macAddress,
    required this.status,
    required this.createdAt,
    this.username,
    this.token,
    this.expirationDate,
    this.lastError,
  });

  final String id;
  final String alias;
  final StalkerEndpoint endpoint;
  final String macAddress;
  final String? username;
  final String? token;
  final StalkerAccountStatus status;
  final DateTime createdAt;
  final DateTime? expirationDate;
  final String? lastError;

  StalkerAccount copyWith({
    String? alias,
    StalkerEndpoint? endpoint,
    String? macAddress,
    String? username,
    String? token,
    StalkerAccountStatus? status,
    DateTime? createdAt,
    DateTime? expirationDate,
    String? lastError,
  }) {
    return StalkerAccount(
      id: id,
      alias: alias ?? this.alias,
      endpoint: endpoint ?? this.endpoint,
      macAddress: macAddress ?? this.macAddress,
      username: username ?? this.username,
      token: token ?? this.token,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expirationDate: expirationDate ?? this.expirationDate,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
        id,
        alias,
        endpoint,
        macAddress,
        username,
        token,
        status,
        createdAt,
        expirationDate,
        lastError,
      ];
}

