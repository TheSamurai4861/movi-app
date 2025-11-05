import '../di/injector.dart';
import 'logger.dart';

AppLogger get _logger => sl<AppLogger>();

void logDebug(String message) => _logger.debug(message);

void logInfo(String message) => _logger.info(message);

void logWarn(String message) => _logger.warn(message);

void logError(String message, [Object? error, StackTrace? stackTrace]) =>
    _logger.error(message, error, stackTrace);
