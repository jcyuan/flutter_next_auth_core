/// Abstract logger interface
abstract class Logger {
  /// Logs an error message
  void error(String message, [Object? error, StackTrace? stackTrace]);
  
  /// Logs an info message
  void info(String message);
  
  /// Logs a debug message
  void debug(String message);
  
  /// Logs a warning message
  void warn(String message);
}
