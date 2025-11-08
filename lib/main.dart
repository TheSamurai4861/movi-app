import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/core/config/config_module.dart';
import 'src/core/config/env/environment_loader.dart';
import 'src/core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loader = EnvironmentLoader();
  final flavor = loader.load();
  final config = await registerConfig(flavor: flavor);
  await initDependencies(appConfig: config);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
