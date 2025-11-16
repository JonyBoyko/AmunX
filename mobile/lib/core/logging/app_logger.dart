import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class AppLogger {
  static const String _tag = '[AmunX]';
  static final List<String> _logs = [];
  static const int _maxLogs = 1000;

  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String? tag, Object? error}) {
    _log(LogLevel.info, message, tag: tag, error: error);
  }

  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag ?? _tag;
    
    final logMessage = '$timestamp [$levelStr] $tagStr: $message';
    
    // Print to console
    if (kDebugMode) {
      print(logMessage);
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null) {
        print('  StackTrace: $stackTrace');
      }
    }

    // Store in memory (for later export if needed)
    _logs.add(logMessage);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  static List<String> getAllLogs() => List.unmodifiable(_logs);

  static void clearLogs() => _logs.clear();

  static String getLogsAsString() => _logs.join('\n');
}

