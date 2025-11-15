import 'package:movi/src/core/logging/category_logger.dart';
import 'package:movi/src/core/logging/logger.dart';

void logDebug(AppLogger logger, String message) => logger.debug(message);

void logInfo(AppLogger logger, String message) => logger.info(message);

void logWarn(AppLogger logger, String message) => logger.warn(message);

void logError(
  AppLogger logger,
  String message, [
  Object? error,
  StackTrace? stackTrace,
]) => logger.error(message, error, stackTrace);

AppLogger categoryLogger(AppLogger logger, String category) =>
    CategoryLogger(logger, category);

AppLogger networkLogger(AppLogger logger) => categoryLogger(logger, 'network');
AppLogger uiLogger(AppLogger logger) => categoryLogger(logger, 'ui');
