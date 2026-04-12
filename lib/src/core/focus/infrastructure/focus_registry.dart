import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';

class FocusRegionRegistration {
  const FocusRegionRegistration({
    required this.binding,
    this.exitMap = const FocusRegionExitMap.empty(),
  });

  final FocusRegionBinding binding;
  final FocusRegionExitMap exitMap;
}

class FocusRegistry {
  final Map<AppFocusRegionId, FocusRegionRegistration> _registrations =
      <AppFocusRegionId, FocusRegionRegistration>{};

  void register(
    AppFocusRegionId id,
    FocusRegionBinding binding, {
    FocusRegionExitMap exitMap = const FocusRegionExitMap.empty(),
  }) {
    _registrations[id] = FocusRegionRegistration(
      binding: binding,
      exitMap: exitMap,
    );
  }

  void unregister(AppFocusRegionId id) {
    _registrations.remove(id);
  }

  FocusRegionRegistration? registrationFor(AppFocusRegionId id) {
    return _registrations[id];
  }

  bool contains(AppFocusRegionId id) {
    return _registrations.containsKey(id);
  }

  Set<AppFocusRegionId> get registeredRegionIds {
    return Set<AppFocusRegionId>.unmodifiable(_registrations.keys);
  }
}
