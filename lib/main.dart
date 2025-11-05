import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/core/di/injector.dart';

const kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
const kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.dev.example.com');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies(); // Prépare DI

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
