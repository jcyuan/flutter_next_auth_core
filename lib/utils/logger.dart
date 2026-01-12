abstract class Logger {
  void error(String message, [Object? error, StackTrace? stackTrace]);
  void info(String message);
  void debug(String message);
  void warn(String message);
}

