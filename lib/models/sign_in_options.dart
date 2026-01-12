/// Email sign in options (parameters correspond to NextAuth callback query parameters)
class EmailSignInOptions {
  final String email;
  final String code;
  final String turnstileToken;

  EmailSignInOptions({required this.email, required this.code, required this.turnstileToken});

  Map<String, String> toJson() => {
    'email': email,
    'code': code,
    'turnstile': turnstileToken,
  };
}

class CredentialsSignInOptions {
  final String email;
  final String password;
  final String turnstileToken;

  CredentialsSignInOptions({required this.email, required this.password, required this.turnstileToken});

  Map<String, String> toJson() => {
    'email': email,
    'password': password,
    'turnstile': turnstileToken,
  };
}

class OAuthSignInOptions {
  final String provider;
  final String turnstileToken;

  OAuthSignInOptions({required this.provider, required this.turnstileToken});

  Map<String, String?> toJson() => {
    'provider': provider,
    'turnstile': turnstileToken,
  };
}

class RegisterWithCredentialsOptions {
  final String email;
  final String password;
  final String turnstileToken;

  RegisterWithCredentialsOptions({required this.email, required this.password, required this.turnstileToken});

  Map<String, String> toJson() => {
    'email': email,
    'password': password,
    'turnstile': turnstileToken,
  };
}

class ForgotPasswordOptions {
  final String email;
  final String turnstileToken;

  ForgotPasswordOptions({required this.email, required this.turnstileToken});

  Map<String, String> toJson() => {
    'email': email,
    'turnstile': turnstileToken,
  };
}

class ResetPasswordOptions {
  final String email;
  final String code;
  final String password;
  final String turnstileToken;

  ResetPasswordOptions({required this.email, required this.code, required this.password, required this.turnstileToken});

  Map<String, String> toJson() => {
    'email': email,
    'code': code,
    'password': password,
    'turnstile': turnstileToken,
  };
}
