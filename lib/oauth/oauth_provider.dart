/// OAuth authorization data containing tokens
class OAuthAuthorizationData {
  /// OAuth authorization code
  final String? authorizationCode;
  
  /// ID token from OAuth provider
  final String idToken;

  /// Creates OAuth authorization data
  OAuthAuthorizationData({
    required this.authorizationCode,
    required this.idToken,
  });

  /// Checks if authorization code is valid
  bool get hasValidAuthorizationCode =>
      authorizationCode != null && authorizationCode!.isNotEmpty;
  
  /// Checks if ID token is valid
  bool get hasValidIdToken => idToken.isNotEmpty;
}

/// Abstract OAuth provider interface
abstract class OAuthProvider {
  /// Gets the OAuth provider name
  String get providerName;
  
  /// Gets the OAuth scopes
  List<String> get scopes;
  
  /// Checks if the provider is initialized
  bool get isInitialized;
  
  /// Initializes the OAuth provider
  Future<void> initialize();
  
  /// Gets authorization data from the OAuth provider
  Future<OAuthAuthorizationData> getAuthorizationData();
  
  /// Signs out from the OAuth provider
  Future<void> signOut();
}
