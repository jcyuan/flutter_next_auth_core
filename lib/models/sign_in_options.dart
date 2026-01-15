/// Options for email-based sign in
class EmailSignInOptions {
  /// User email address
  final String email;
  
  /// Verification token
  /// If the token is missing in emailOptions, a verification code will be sent to the email,
  /// otherwise the server-side sign-in process will be invoked.
  final String? token;
  
  /// Optional Turnstile token for bot protection by your server
  final String? turnstileToken;

  /// Optional locale for the email sign-in process
  final String? locale;

  /// Creates email sign in options
  EmailSignInOptions({
    required this.email,
    this.token,
    this.turnstileToken,
    this.locale,
  });

  /// Converts to JSON map
  Map<String, String> toJson() {
    final params = {'email': email };
    if (token != null) {
      params['token'] = token!;
    }
    if (turnstileToken != null) {
      params['turnstile'] = turnstileToken!;
    }
    if (locale != null) {
      params['locale'] = locale!;
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
