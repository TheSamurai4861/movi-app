## Run Windows avec logs

Run standard :

```powershell
flutter run -d windows --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true *>&1 | Tee-Object -FilePath output/flutter-run-windows.log
```

## Run Android avec logs

Si un emulateur ou device Android est connecte :

```powershell
flutter run -d android --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true *>&1 | Tee-Object -FilePath output/flutter-run-android.log
```

## Analyse statique avec logs

```powershell
flutter analyze *>&1 | Tee-Object -FilePath output/flutter-analyze.log
```

## Tests avec logs

Tous les tests :

```powershell
flutter test --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-test.log
```

## Build Windows avec logs

```powershell
flutter build windows --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-build-windows.log
```

## Build APK avec logs

```powershell
flutter build apk --debug --dart-define-from-file=.env *>&1 | Tee-Object -FilePath output/flutter-build-apk-debug.log
```