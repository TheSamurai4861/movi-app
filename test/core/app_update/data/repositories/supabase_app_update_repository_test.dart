import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/app_update/data/datasources/app_update_cache_data_source.dart';
import 'package:movi/src/core/app_update/data/models/app_update_remote_response.dart';
import 'package:movi/src/core/app_update/data/repositories/supabase_app_update_repository.dart';
import 'package:movi/src/core/app_update/data/services/app_update_edge_service.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late AppUpdateContext context;
  late _MemorySecureStorage storage;
  late AppUpdateCacheDataSource cacheDataSource;
  late _TestLogger logger;

  setUp(() async {
    context = const AppUpdateContext(
      appId: 'movi',
      environment: 'prod',
      currentVersion: '1.0.2',
      buildNumber: '9',
      platform: 'windows',
    );
    storage = _MemorySecureStorage();
    cacheDataSource = await AppUpdateCacheDataSource.create(storage: storage);
    logger = _TestLogger();
  });

  test('fails open on remote 500 when no usable cache exists', () async {
    final repository = SupabaseAppUpdateRepository(
      remoteDataSource: _FakeAppUpdateEdgeService(
        onFetch: (_) async => throw const FunctionException(status: 500),
      ),
      cacheDataSource: cacheDataSource,
      logger: logger,
    );

    final decision = await repository.check(context);

    expect(decision.status, AppUpdateStatus.allowed);
    expect(decision.currentVersion, context.currentVersion);
    expect(decision.platform, context.platform);
    expect(decision.reasonCode, 'app_update_remote_server_error');
    expect(logger.events.last.level, LogLevel.warn);
  });

  test('uses cached decision before fail-open when cache is still usable', () async {
    await cacheDataSource.write(
      AppUpdateRemoteResponse(
        status: AppUpdateStatus.softUpdate,
        reasonCode: 'cached_soft_update',
        currentVersion: context.currentVersion,
        platform: context.platform,
        checkedAt: DateTime.now().toUtc(),
      ),
    );

    final repository = SupabaseAppUpdateRepository(
      remoteDataSource: _FakeAppUpdateEdgeService(
        onFetch: (_) async => throw const FunctionException(status: 500),
      ),
      cacheDataSource: cacheDataSource,
      logger: logger,
    );

    final decision = await repository.check(context);

    expect(decision.status, AppUpdateStatus.softUpdate);
    expect(decision.reasonCode, 'cached_soft_update');
  });

  test('rethrows non-retryable app update errors without usable cache', () async {
    final repository = SupabaseAppUpdateRepository(
      remoteDataSource: _FakeAppUpdateEdgeService(
        onFetch: (_) async => throw const FormatException('bad payload'),
      ),
      cacheDataSource: cacheDataSource,
      logger: logger,
    );

    expect(repository.check(context), throwsFormatException);
  });
}

class _FakeAppUpdateEdgeService extends AppUpdateEdgeService {
  _FakeAppUpdateEdgeService({required this.onFetch})
    : super(SupabaseClient('https://example.com', 'test-anon-key'));

  final Future<AppUpdateRemoteResponse> Function(AppUpdateContext context)
      onFetch;

  @override
  Future<AppUpdateRemoteResponse> fetchDecision(AppUpdateContext context) {
    return onFetch(context);
  }
}

class _MemorySecureStorage extends FlutterSecureStorage {
  _MemorySecureStorage();

  final Map<String, String> _data = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
      return;
    }
    _data[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

class _TestLogger extends AppLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      LogEvent(
        timestamp: DateTime.now().toUtc(),
        level: level,
        message: message,
        category: category,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
