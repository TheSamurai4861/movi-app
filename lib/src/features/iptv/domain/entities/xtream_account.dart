import 'package:equatable/equatable.dart';

import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

enum XtreamAccountStatus { pending, active, expired, error }

class XtreamAccount extends Equatable {
  const XtreamAccount({
    required this.id,
    required this.alias,
    required this.endpoint,
    required this.username,
    required this.status,
    required this.createdAt,
    this.expirationDate,
    this.lastError,
  });

  final String id;
  final String alias;
  final XtreamEndpoint endpoint;
  final String username;
  final XtreamAccountStatus status;
  final DateTime createdAt;
  final DateTime? expirationDate;
  final String? lastError;

  XtreamAccount copyWith({
    String? alias,
    XtreamEndpoint? endpoint,
    String? username,
    XtreamAccountStatus? status,
    DateTime? createdAt,
    DateTime? expirationDate,
    String? lastError,
  }) {
    return XtreamAccount(
      id: id,
      alias: alias ?? this.alias,
      endpoint: endpoint ?? this.endpoint,
      username: username ?? this.username,
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
    username,
    status,
    createdAt,
    expirationDate,
    lastError,
  ];
}
