/// Session authentication status
enum SessionStatus { 
  /// Initial state before any authentication check
  initial, 
  /// Currently loading/checking authentication
  loading, 
  /// User is authenticated
  authenticated, 
  /// User is not authenticated
  unauthenticated 
}
