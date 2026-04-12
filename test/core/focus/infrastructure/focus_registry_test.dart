import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/infrastructure/focus_registry.dart';

void main() {
  test('register stores a focus region registration', () {
    final node = FocusNode(debugLabel: 'primary');
    addTearDown(node.dispose);
    final binding = FocusRegionBinding(resolvePrimaryEntryNode: () => node);
    final registry = FocusRegistry();

    registry.register(AppFocusRegionId.searchInput, binding);

    final registration = registry.registrationFor(AppFocusRegionId.searchInput);
    expect(registration, isNotNull);
    expect(registration!.binding, same(binding));
    expect(registry.contains(AppFocusRegionId.searchInput), isTrue);
  });

  test('register replaces an existing registration', () {
    final firstNode = FocusNode(debugLabel: 'first');
    final secondNode = FocusNode(debugLabel: 'second');
    addTearDown(firstNode.dispose);
    addTearDown(secondNode.dispose);
    final firstBinding = FocusRegionBinding(
      resolvePrimaryEntryNode: () => firstNode,
    );
    final secondBinding = FocusRegionBinding(
      resolvePrimaryEntryNode: () => secondNode,
    );
    final registry = FocusRegistry()
      ..register(AppFocusRegionId.searchInput, firstBinding)
      ..register(AppFocusRegionId.searchInput, secondBinding);

    final registration = registry.registrationFor(AppFocusRegionId.searchInput);
    expect(registration!.binding, same(secondBinding));
  });

  test('unregister removes an existing registration', () {
    final node = FocusNode(debugLabel: 'primary');
    addTearDown(node.dispose);
    final registry = FocusRegistry()
      ..register(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => node),
      );

    registry.unregister(AppFocusRegionId.searchInput);

    expect(registry.contains(AppFocusRegionId.searchInput), isFalse);
    expect(registry.registrationFor(AppFocusRegionId.searchInput), isNull);
  });

  test('registeredRegionIds returns an unmodifiable set', () {
    final node = FocusNode(debugLabel: 'primary');
    addTearDown(node.dispose);
    final registry = FocusRegistry()
      ..register(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => node),
      );

    expect(
      () => registry.registeredRegionIds.add(AppFocusRegionId.shellSidebar),
      throwsUnsupportedError,
    );
  });

  test('stores the exit map with the registration', () {
    final node = FocusNode(debugLabel: 'primary');
    addTearDown(node.dispose);
    final exitMap = FocusRegionExitMap({
      DirectionalEdge.left: AppFocusRegionId.shellSidebar,
    });
    final registry = FocusRegistry()
      ..register(
        AppFocusRegionId.searchInput,
        FocusRegionBinding(resolvePrimaryEntryNode: () => node),
        exitMap: exitMap,
      );

    final registration = registry.registrationFor(AppFocusRegionId.searchInput);
    expect(registration!.exitMap, same(exitMap));
  });
}
