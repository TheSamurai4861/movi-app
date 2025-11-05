import 'package:flutter/material.dart';

const kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
const kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.dev.example.com');

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movi ($kFlavor)',
      home: Scaffold(
        appBar: AppBar(title: Text('Movi – $kFlavor')),
        body: Center(
          child: Text('API: $kApiBaseUrl'),
        ),
      ),
    );
  }
}
