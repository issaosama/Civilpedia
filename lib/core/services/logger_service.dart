class LoggerService {
  static void debug(String message) {
    _log('DEBUG', message);
  }

  static void info(String message) {
    _log('INFO', message);
  }

  static void warning(String message) {
    _log('WARNING', message);
  }

  static void error(String message, [Object? exception]) {
    _log('ERROR', '$message${exception != null ? ' | $exception' : ''}');
  }

  static void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$timestamp] [$level] $message');
  }
}
