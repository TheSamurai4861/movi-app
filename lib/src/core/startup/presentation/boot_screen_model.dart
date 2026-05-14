import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

enum BootScreenType {
  simpleLoading,
  catalogLoading,
  actionRequired,
  recovery,
  openingHome,
  homePartialNotice,
  technicalFailure,
}

enum BootFocusTarget { none, primaryAction, secondaryAction }

enum BootScreenSeverity { info, warning, error }

final class BootScreenModel {
  const BootScreenModel({
    required this.screenType,
    required this.message,
    required this.reasonCode,
    required this.isInteractive,
    required this.initialFocus,
    required this.severity,
    required this.showLogo,
    required this.showProgress,
    this.title,
    this.secondaryMessage,
    this.primaryAction,
    this.primaryActionLabel,
    this.secondaryAction,
    this.secondaryActionLabel,
    this.destination,
    this.metadata = const <String, Object?>{},
  }) : assert(reasonCode != ''),
       assert(
         !isInteractive ||
             (primaryAction != null &&
                 primaryActionLabel != null &&
                 primaryActionLabel != ''),
       ),
       assert(
         isInteractive ||
             (primaryAction == null &&
                 primaryActionLabel == null &&
                 secondaryAction == null &&
                 secondaryActionLabel == null &&
                 initialFocus == BootFocusTarget.none),
       ),
       assert(
         secondaryAction == null ||
             (secondaryActionLabel != null && secondaryActionLabel != ''),
       );

  final BootScreenType screenType;
  final String? title;
  final String message;
  final String? secondaryMessage;
  final BootActionIntent? primaryAction;
  final String? primaryActionLabel;
  final BootActionIntent? secondaryAction;
  final String? secondaryActionLabel;
  final BootstrapDestination? destination;
  final String reasonCode;
  final bool isInteractive;
  final BootFocusTarget initialFocus;
  final BootScreenSeverity severity;
  final bool showLogo;
  final bool showProgress;
  final Map<String, Object?> metadata;
}
