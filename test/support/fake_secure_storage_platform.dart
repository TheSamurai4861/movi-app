import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

final class FakeSecureStoragePlatform extends FlutterSecureStoragePlatform {
  FakeSecureStoragePlatform([Map<String, String>? seed])
    : data = Map<String, String>.from(seed ?? const <String, String>{});

  final Map<String, String> data;

  Object? readError;
  Object? writeError;
  Object? deleteError;
  Object? readAllError;
  Object? containsKeyError;
  Object? deleteAllError;

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    if (containsKeyError != null) {
      throw containsKeyError!;
    }
    return data.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    if (deleteError != null) {
      throw deleteError!;
    }
    data.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    if (deleteAllError != null) {
      throw deleteAllError!;
    }
    data.clear();
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    if (readError != null) {
      throw readError!;
    }
    return data[key];
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    if (readAllError != null) {
      throw readAllError!;
    }
    return Map<String, String>.from(data);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    if (writeError != null) {
      throw writeError!;
    }
    data[key] = value;
  }
}
