import 'package:flutter_next_auth/http/http_client.dart';
import 'package:flutter_next_auth/utils/logger.dart';

class NextAuthConfig<T extends Map<String, dynamic>> {
  /// server address (required)
  final String domain;
  /// auth api base path (optional)
  final String authBasePath;
  /// HTTP client (required)
  final HttpClient httpClient;
  /// Logger instance (optional)
  final Logger? logger;
  /// server session cookie name (optional, default: __Secure-authjs.session-token for HTTPS, authjs.session-token for HTTP, must same as the one in the server)
  final String serverSessionCookieName;
  /// server CSRF cookie name (optional, must same as the one in the server)
  final String serverCSRFTokenCookieName;

  NextAuthConfig({
    required this.domain,
    this.authBasePath = '/api/auth',
    required this.httpClient,
    this.logger,
    this.serverSessionCookieName = "__miearapp.session-token",
    this.serverCSRFTokenCookieName = "__miearapp.csrf-token",
  });
}
