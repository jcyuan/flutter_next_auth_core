/// Options for email-based sign in
class EmailSignInOptions {
  /// User email address
  final String email;
  
  /// Verification code
  final String code;
  
  /// Optional Turnstile token for bot protection
  final String? turnstileToken;

  /// Creates email sign in options
  EmailSignInOptions({
    required this.email,
    required this.code,
    this.turnstileToken,
  });

  /// Converts to JSON map
  Map<String, String> toJson() {
    final params = {'email': email, 'code': code};
    if (turnstileToken != null) {
      params['turnstile'] = turnstileToken!;
    }
    return params;
  }
}

/// Options for credentials-based sign in
class CredentialsSignInOptions {
  /// User email address
  final String email;
  
  /// User password
  final String password;
  
  /// Optional Turnstile token for bot protection
  final String? turnstileToken;

  /// Creates credentials sign in options
  CredentialsSignInOptions({
    required this.email,
    required this.password,
    this.turnstileToken,
  });

  /// Converts to JSON map
  Map<String, String> toJson() {
    final params = {'email': email, 'password': password};
    if (turnstileToken != null) {
      params['turnstile'] = turnstileToken!;
    }
    return params;
  }
}

/// Options for OAuth-based sign in
class OAuthSignInOptions {
  /// OAuth provider identifier
  final String provider;
  
  /// Optional Turnstile token for bot protection
  final String? turnstileToken;

  /// Creates OAuth sign in options
  OAuthSignInOptions({required this.provider, this.turnstileToken});

  /// Converts to JSON map
  Map<String, String> toJson() {
    final params = {'provider': provider};
    if (turnstileToken != null) {
      params['turnstile'] = turnstileToken!;
    }
    return params;
  }
}
