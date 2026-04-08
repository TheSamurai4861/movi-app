# DELIVERY MANIFEST

## Added
- `lib/src/core/app_update/domain/entities/app_update_decision.dart`
- `lib/src/core/app_update/domain/entities/app_update_context.dart`
- `lib/src/core/app_update/domain/repositories/app_update_repository.dart`
- `lib/src/core/app_update/domain/services/app_runtime_info_provider.dart`
- `lib/src/core/app_update/application/check_app_update_requirement.dart`
- `lib/src/core/app_update/data/models/app_update_remote_request.dart`
- `lib/src/core/app_update/data/models/app_update_remote_response.dart`
- `lib/src/core/app_update/data/datasources/app_update_cache_data_source.dart`
- `lib/src/core/app_update/data/services/package_info_app_runtime_info_provider.dart`
- `lib/src/core/app_update/data/services/app_update_edge_service.dart`
- `lib/src/core/app_update/data/repositories/supabase_app_update_repository.dart`
- `lib/src/core/app_update/presentation/providers/app_update_provider.dart`
- `lib/src/core/app_update/presentation/widgets/app_update_blocked_screen.dart`
- `supabase/functions/check-app-version/index.ts`
- `supabase/functions/check-app-version/README.md`
- `supabase/migrations/20260408_create_app_version_policies.sql`
- `docs/app_update_integration.md`
- `test/core/app_update/application/check_app_update_requirement_test.dart`

## Modified
- `pubspec.yaml`
- `lib/src/core/di/injector.dart`
- `lib/src/core/startup/app_startup_gate.dart`

## Notes
- Le contrôle de version distant bloque l'entrée uniquement pour `force_update`.
- Les URL de stores dans la migration SQL sont des placeholders à remplacer.
- Validation statique et tests non exécutés ici : l'environnement ne fournit ni `dart` ni `flutter`.
