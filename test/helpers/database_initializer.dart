import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_path_provider.dart';

class _AllowHttpOverrides extends HttpOverrides {}

Future<void> initTestDatabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProviderPlatform();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  HttpOverrides.global = _AllowHttpOverrides();
  // Ensure a clean DB for each test run
  try {
    final docs = await PathProviderPlatform.instance.getApplicationDocumentsPath();
    if (docs != null && docs.isNotEmpty) {
      final dir = Directory(docs)..createSync(recursive: true);
      final dbFile = File('${dir.path}/movi.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    }
  } catch (_) {
    // best-effort cleanup only
  }
}
