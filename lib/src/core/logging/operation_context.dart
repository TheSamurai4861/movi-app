import 'dart:math';
import 'dart:async';

/// Zone key used to attach an operation correlation id.
const Object operationIdZoneKey = Object();

/// Returns the current correlation id if present.
String? currentOperationId() => Zone.current[operationIdZoneKey] as String?;

/// Generate a short, locally-unique operation id.
String generateOperationId({String prefix = 'op'}) {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final rnd = Random().nextInt(1 << 20);
  return '${prefix}_${ts.toRadixString(36)}_${rnd.toRadixString(36)}';
}

/// Run a function inside a zone that carries an operation id.
T runWithOperationId<T>(
  T Function() body, {
  String? operationId,
  String prefix = 'op',
}) {
  final id = operationId ?? generateOperationId(prefix: prefix);
  return runZoned(body, zoneValues: <Object?, Object?>{operationIdZoneKey: id});
}
