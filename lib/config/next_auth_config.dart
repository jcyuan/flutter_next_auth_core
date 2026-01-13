import 'package:flutter_next_auth_core/core/utils/session_serializer.dart';
import 'package:flutter_next_auth_core/http/http_client.dart';
import 'package:flutter_next_auth_core/utils/logger.dart';

/// Configuration for NextAuth client
class NextAuthConfig<T> {
  /// server address (required)
  final String domain;

  /// auth api base path (optional)
  final String authBasePath;

  /// HTTP client (required)
  final HttpClient httpClient;

  /// Logger instance (optional)
  final Logger? logger;

  /// Session serializer (required)
  final SessionSerializer<T> sessionSerializer;

  /// server session cookie name (optional, default: __Secure-next-auth.session-token for HTTPS, next-auth.session-token for HTTP, must same as the one in the server)
  final String serverSessionCookieName;

  /// server CSRF cookie name (optional, must same as the one in the server， default: __Host-next-auth.csrf-token for HTTPS, next-auth.csrf-token for HTTP)
  final String serverCSRFTokenCookieName;

  /// Creates a NextAuth configuration
  NextAuthConfig({
    required this.domain,
    this.authBasePath = '/api/auth',
    required this.httpClient,
    required this.sessionSerializer,
    this.logger,
    this.serverSessionCookieName = "next-auth.session-token",
    this.serverCSRFTokenCookieName = "next-auth.csrf-token",
  });
}
