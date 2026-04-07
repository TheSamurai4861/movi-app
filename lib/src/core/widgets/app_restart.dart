import 'package:flutter/widgets.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/tunnel_state.dart';

class AppRestart extends StatefulWidget {
  const AppRestart({super.key, required this.child});

  final Widget child;

  /// Best-effort reset of bootstrap-related singletons so a restart can
  /// re-run the `/launch` journey and preload Home.
  static void resetBootstrapState() {
    try {
      if (sl.isRegistered<AppLaunchStateRegistry>()) {
        sl<AppLaunchStateRegistry>().update(const AppLaunchState());
      }
    } catch (_) {
      // best-effort
    }

    try {
      if (sl.isRegistered<TunnelStateRegistry>()) {
        sl<TunnelStateRegistry>().update(TunnelState.empty);
      }
    } catch (_) {
      // best-effort
    }
  }

  static void restartApp(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppRestartState>();
    state?.restart();
  }

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();

  void restart() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
