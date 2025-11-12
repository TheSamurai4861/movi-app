import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/category_logger.dart';

AppLogger get _logger => sl<AppLogger>();

void logDebug(String message) => _logger.debug(message);

void logInfo(String message) => _logger.info(message);

void logWarn(String message) => _logger.warn(message);

void logError(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.error(message, error, stackTrace);

AppLogger categoryLogger(String category) => CategoryLogger(_logger, category);

AppLogger get networkLogger => categoryLogger('network');
AppLogger get uiLogger => categoryLogger('ui');
