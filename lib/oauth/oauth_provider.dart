class OAuthAuthorizationData {
  final String? authorizationCode;
  final String idToken;

  OAuthAuthorizationData({
    required this.authorizationCode,
    required this.idToken,
  });

  bool get hasValidAuthorizationCode => authorizationCode != null && authorizationCode!.isNotEmpty;
  bool get hasValidIdToken => idToken.isNotEmpty;
}

abstract class OAuthProvider {
  String get providerName;
  List<String> get scopes;
  bool get isInitialized;
  Future<void> initialize();
  Future<OAuthAuthorizationData> getAuthorizationData();
  Future<void> signOut();
}
