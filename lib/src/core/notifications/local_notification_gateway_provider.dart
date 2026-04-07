import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/notifications/flutter_local_notification_gateway.dart';
import 'package:movi/src/core/notifications/local_notification_gateway.dart';

final localNotificationGatewayProvider = Provider<LocalNotificationGateway>((
  ref,
) {
  return FlutterLocalNotificationGateway();
});
