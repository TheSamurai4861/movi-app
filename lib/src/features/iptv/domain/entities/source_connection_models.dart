import 'package:equatable/equatable.dart';

enum SourceKind { xtream, m3u, stalkerPortal, custom }

enum RouteProfileKind { defaultRoute, proxy }

class RouteProfile extends Equatable {
  const RouteProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.kind,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.proxyScheme,
    this.proxyHost,
    this.proxyPort,
  });

  static const String defaultId = 'default';

  factory RouteProfile.defaultProfile({String ownerId = 'system'}) {
    final now = DateTime.now();
    return RouteProfile(
      id: defaultId,
      ownerId: ownerId,
      name: 'Par defaut',
      kind: RouteProfileKind.defaultRoute,
      enabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String ownerId;
  final String name;
  final RouteProfileKind kind;
  final String? proxyScheme;
  final String? proxyHost;
  final int? proxyPort;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDefault => id == defaultId;

  RouteProfile copyWith({
    String? name,
    RouteProfileKind? kind,
    String? proxyScheme,
    String? proxyHost,
    int? proxyPort,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteProfile(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      proxyScheme: proxyScheme ?? this.proxyScheme,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    ownerId,
    name,
    kind,
    proxyScheme,
    proxyHost,
    proxyPort,
    enabled,
    createdAt,
    updatedAt,
  ];
}

class SourceConnectionPolicy extends Equatable {
  const SourceConnectionPolicy({
    required this.ownerId,
    required this.accountId,
    required this.sourceKind,
    required this.preferredRouteProfileId,
    required this.fallbackRouteProfileIds,
    required this.updatedAt,
    this.lastWorkingRouteProfileId,
  });

  factory SourceConnectionPolicy.defaults({
    required String ownerId,
    required String accountId,
    required SourceKind sourceKind,
  }) {
    return SourceConnectionPolicy(
      ownerId: ownerId,
      accountId: accountId,
      sourceKind: sourceKind,
      preferredRouteProfileId: RouteProfile.defaultId,
      fallbackRouteProfileIds: const <String>[],
      lastWorkingRouteProfileId: null,
      updatedAt: DateTime.now(),
    );
  }

  final String ownerId;
  final String accountId;
  final SourceKind sourceKind;
  final String preferredRouteProfileId;
  final List<String> fallbackRouteProfileIds;
  final String? lastWorkingRouteProfileId;
  final DateTime updatedAt;

  SourceConnectionPolicy copyWith({
    String? preferredRouteProfileId,
    List<String>? fallbackRouteProfileIds,
    String? lastWorkingRouteProfileId,
    bool clearLastWorkingRouteProfileId = false,
    DateTime? updatedAt,
  }) {
    return SourceConnectionPolicy(
      ownerId: ownerId,
      accountId: accountId,
      sourceKind: sourceKind,
      preferredRouteProfileId:
          preferredRouteProfileId ?? this.preferredRouteProfileId,
      fallbackRouteProfileIds:
          fallbackRouteProfileIds ?? this.fallbackRouteProfileIds,
      lastWorkingRouteProfileId: clearLastWorkingRouteProfileId
          ? null
          : lastWorkingRouteProfileId ?? this.lastWorkingRouteProfileId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    ownerId,
    accountId,
    sourceKind,
    preferredRouteProfileId,
    fallbackRouteProfileIds,
    lastWorkingRouteProfileId,
    updatedAt,
  ];
}

class RouteProfileCredentials extends Equatable {
  const RouteProfileCredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  List<Object?> get props => <Object?>[username, password];
}
