import 'dart:io';

import 'package:flutter_next_auth_core/cache/token_cache.dart';
import 'package:flutter_next_auth_core/config/next_auth_config.dart';
import 'package:flutter_next_auth_core/core/exception/signin_exception.dart';
import 'package:flutter_next_auth_core/http/http_client.dart';
import 'package:flutter_next_auth_core/http/http_response.dart';
import 'package:flutter_next_auth_core/models/sign_in_error.dart';
import 'package:flutter_next_auth_core/models/sign_in_options.dart';
import 'package:flutter_next_auth_core/models/sign_in_response.dart';
import 'package:flutter_next_auth_core/oauth/oauth_provider_registry.dart';
import 'package:flutter_next_auth_core/utils/api_utils.dart' show apiBaseUrl;
import 'package:flutter_next_auth_core/utils/logger.dart';

class AuthService<T> {
  final NextAuthConfig _config;
  final OAuthProviderRegistry _oauthRegistry;
  final TokenCache _tokenCache;

  AuthService({
    required NextAuthConfig config,
    required OAuthProviderRegistry oauthRegistry,
    required TokenCache tokenCache,
  }) : _config = config,
       _oauthRegistry = oauthRegistry,
       _tokenCache = tokenCache;

  Logger? get logger => _config.logger;

  /// Sign in with email, credentials or OAuth provider
  /// - email: sign in with email (If the token is missing in emailOptions, a verification code will be sent to the email and a token will be returned. 
  ///          Otherwise, the server-side sign-in process will be invoked. Therefore, the email sign-in flow requires calling this method twice.)
  /// - credentials: sign in with credentials (you are responsible for providing the credentials to the signIn method)
  /// - OAuth provider: sign in with OAuth provider (you are responsible for implementing the OAuth provider)
  Future<SignInResponse> signIn(
    String provider, {
    EmailSignInOptions? emailOptions,
    CredentialsSignInOptions? credentialsOptions,
    OAuthSignInOptions? oauthOptions,
  }) async {
    try {
      SignInResponse response;
      if (provider == 'email') {
        assert(
          emailOptions != null,
          'emailOptions is required for email provider',
        );
        response = await _signInWithEmail(emailOptions!);
      } else if (provider == 'credentials') {
        assert(
          credentialsOptions != null,
          'credentialsOptions is required for credentials provider',
        );
        response = await _signInWithCredentials(credentialsOptions!);
      } else {
        assert(
          oauthOptions != null,
          'oauthOptions is required for OAuth provider',
        );
        response = await _signInWithOAuth(provider, oauthOptions!);
      }

      return response;
    } catch (e) {
      logger?.error('signIn error', e);
      return SignInResponse(
        error: SignInError(
          code: SignInErrorCode.serverError,
          exception: e is Exception ? e : SignInException.fromObject(e),
        ),
        status: 500,
        ok: false,
      );
    }
  }

  Future<SignInResponse> _signInWithEmail(EmailSignInOptions options) async {
    if (options.email.isEmpty) {
      throw ArgumentError('email is required');
    }

    if (options.token == null || options.token!.isEmpty) {
      // Send verification code to email
      final url = apiBaseUrl(
        _config.domain,
        _config.authBasePath,
        'signin/email',
      );

      final response = await _config.httpClient.post(
        url,
        body: {
          'email': options.email,
          'csrfToken': await getCSRFToken(),
          ...options.toJson(),
          'json': true,
        },
        options: HttpClientOptions(
          contentType: 'application/x-www-form-urlencoded',
          responseType: HttpClientResponseType.json,
          cookies: await _getCookieList(),
          headers: {'login-client': 'app'}
        )
      );

      return _handleEmailSendingResponse(response);
    } else {
      // Verify verification code
      final url = apiBaseUrl(
        _config.domain,
        _config.authBasePath,
        'callback/email',
      );

      final queryParams = {
        'email': options.email,
        'token': options.token!,
      };
      final urlWithParams = Uri.parse(url).replace(
        queryParameters: queryParams,
      ).toString();

      final response = await _config.httpClient.get(
        urlWithParams,
        options: HttpClientOptions(
          cookies: await _getCookieList(),
          headers: {'login-client': 'app'},
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      return _handleEmailVerificationResponse(response);
    }
  }
  
  Future<SignInResponse> _handleEmailSendingResponse(
    HttpResponse response,
  ) async {
    final body = response.body as Map<String, dynamic>?;
    final url = body?['url'] as String?;

    if (response.statusCode == 200 &&
        url != null &&
        url.isNotEmpty &&
        url.toLowerCase().contains('verify-request')) {
      await _cacheCSRFCookieFromHeaders(response);
      return SignInResponse(ok: true, status: 200);
    } else {
      String? errorMessage;
      if (url != null && url.isNotEmpty) {
        try {
          final responseUrl = Uri.parse(url);
          errorMessage = responseUrl.queryParameters['error'];
        } catch (_) {}
      }

      logger?.error('email sending response error: $errorMessage');

      return SignInResponse(
        error: SignInError(
          code: SignInErrorCode.serverError,
          exception: SignInException('auth.email.error-send-verification-failed'),
        ),
        status: response.statusCode ?? 500,
        ok: false,
      );
    }
  }
  
  Future<SignInResponse> _handleEmailVerificationResponse(
    HttpResponse response,
  ) async {
    final headers = response.headers;
    final cookies = headers['set-cookie'];
    final accessToken = cookies?.firstWhere(
      (element) => element.startsWith('${_config.serverSessionCookieName}='),
      orElse: () => '',
    );

    if (accessToken != null && accessToken.isNotEmpty) {
      final accessTokenValue = _parseCookieValue(accessToken);
      final accessTokenExpiresAt = _parseCookieExpiration(accessToken);
      await _tokenCache.setAccessToken(
        accessTokenValue,
        expiresAt: accessTokenExpiresAt,
      );

      // cache csrf token
      await _cacheCSRFCookieFromHeaders(response);

      return SignInResponse(ok: true, status: 200);
    } else {
      String? errorMessage;
      if (response.statusCode == 302) {
        final location = headers['location']?.firstOrNull;
        if (location != null && location.isNotEmpty) {
          try {
            final locationUrl = Uri.parse(location);
            errorMessage = locationUrl.queryParameters['error'];
          } catch (_) {}
        }
      }

      logger?.error('email verification response error: $errorMessage');

      return SignInResponse(
        error: SignInError(
          code: SignInErrorCode.invalidLogin,
          exception: SignInException('auth.email.error-verification-failed'),
        ),
        status: response.statusCode ?? 500,
        ok: false,
      );
    }
  }

  Future<Map<String, String>?> _getCookieList({
    bool attachAccessToken = true,
  }) async {
    final cookieList = <String, String>{};

    final csrfCookie = await _tokenCache.getCSRFCookie();
    if (csrfCookie != null && csrfCookie.isNotEmpty) {
      cookieList[_config.serverCSRFTokenCookieName] = csrfCookie;
    }

    if (attachAccessToken) {
      final accessToken = await _tokenCache.getAccessToken();
      if (accessToken != null && accessToken.isValid) {
        cookieList[_config.serverSessionCookieName] = accessToken.token;
      }
    }

    cookieList.removeWhere((key, value) => value.isEmpty);

    return cookieList.isEmpty ? null : cookieList;
  }

  Future<SignInResponse> _signInWithCredentials(
    CredentialsSignInOptions options,
  ) async {
    final url = apiBaseUrl(
      _config.domain,
      _config.authBasePath,
      'callback/credentials',
    );

    final response = await _config.httpClient.post(
      url,
      body: {
        'csrfToken': await getCSRFToken(),
        ...options.toJson(),
        'json': true,
        'redirect': false,
      },
      options: HttpClientOptions(
        contentType: 'application/x-www-form-urlencoded',
        responseType: HttpClientResponseType.json,
        cookies: await _getCookieList(),
        headers: {'login-client': 'app'},
        followRedirects: false,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    return _handleSignInResponse(response);
  }

  Future<SignInResponse> _signInWithOAuth(
    String provider,
    OAuthSignInOptions options,
  ) async {
    final oauthProvider = _oauthRegistry.getProvider(provider);
    if (oauthProvider == null) {
      throw ArgumentError(
        'OAuth provider $provider not found, please register your own OAuth provider',
      );
    }

    if (!oauthProvider.isInitialized) {
      await oauthProvider.initialize();
    }

    final authorizationData = await oauthProvider.getAuthorizationData();
    final url = apiBaseUrl(_config.domain, _config.authBasePath, 'oauth');

    final response = await _config.httpClient.post(
      url,
      body: {
        'provider': provider,
        'idToken': authorizationData.idToken,
        'code': authorizationData.hasValidAuthorizationCode
            ? authorizationData.authorizationCode!
            : null,
        ...options.toJson(),
      },
      options: HttpClientOptions(
        contentType: 'application/json',
        cookies: await _getCookieList(),
        headers: {'login-client': 'app'},
      ),
    );

    return _handleOAuthSignInResponse(response);
  }

  Future<void> _cacheCSRFCookieFromHeaders(HttpResponse response) async {
    final cookies = response.headers['set-cookie'];
    if (cookies != null && cookies.isNotEmpty) {
      try {
        final csrfCookieHeader = cookies.firstWhere(
          (element) =>
              element.startsWith('${_config.serverCSRFTokenCookieName}='),
          orElse: () => '',
        );

        if (csrfCookieHeader.isNotEmpty) {
          final cookieValue = _parseCookieValue(csrfCookieHeader);
          final expiresAt = _parseCookieExpiration(csrfCookieHeader);

          await _tokenCache.setCSRFCookie(cookieValue, expiresAt: expiresAt);
        }
      } catch (e) {
        logger?.error('_cacheCSRFCookieFromHeaders error', e);
      }
    }
  }

  /// Parse cookie value from Set-Cookie header
  /// Format: cookie-name=cookie-value; attributes...
  String? _parseCookieValue(String cookieHeader) {
    final parts = cookieHeader.split(';');
    if (parts.isEmpty) return null;

    final nameValue = parts[0].trim();
    final equalsIndex = nameValue.indexOf('=');
    if (equalsIndex == -1) return null;

    return nameValue.substring(equalsIndex + 1);
  }

  /// Parse cookie expiration from Set-Cookie header
  /// Returns expiration timestamp in milliseconds since epoch, or null if not found
  /// Priority: Max-Age > Expires (Max-Age takes precedence when both are present)
  int? _parseCookieExpiration(String cookieHeader) {
    final parts = cookieHeader.split(';');
    int? expiresValue;

    for (final part in parts) {
      final trimmed = part.trim().toLowerCase();

      if (trimmed.startsWith('max-age=')) {
        final maxAgeValue = trimmed.substring(8).trim();
        try {
          final maxAgeSeconds = int.parse(maxAgeValue);
          if (maxAgeSeconds > 0) {
            // Max-Age has priority, return immediately
            final now = DateTime.now();
            final expiresAt = now.add(Duration(seconds: maxAgeSeconds));
            return expiresAt.millisecondsSinceEpoch;
          }
        } catch (e) {
          logger?.warn('Failed to parse Max-Age: $maxAgeValue, error: $e');
        }
      } else if (trimmed.startsWith('expires=') && expiresValue == null) {
        final expiresDateValue = part.trim().substring(8).trim();
        try {
          // Parse RFC 1123 date format (HTTP-date, must be GMT): "Wed, 21 Oct 2015 07:28:00 GMT"
          DateTime? date;
          try {
            date = HttpDate.parse(expiresDateValue);
          } catch (_) {
            // Fallback: try DateTime.parse for ISO and other formats
            // Remove timezone suffix if present for better compatibility
            final cleanedValue = expiresDateValue.replaceAll(
              RegExp(r'\s+GMT$'),
              '',
            );
            date = DateTime.parse(cleanedValue);
          }
          expiresValue = date.millisecondsSinceEpoch;
        } catch (e) {
          logger?.warn('Failed to parse Expires date: $expiresDateValue, error: $e');
        }
      }
    }

    return expiresValue;
  }

  Future<SignInResponse> _handleSignInResponse(HttpResponse response) async {
    final body = response.body as Map<String, dynamic>?;
    final url = body?['url'];

    if (response.statusCode == 200 &&
        !(url?.toLowerCase().contains('error') ?? true)) {
      // sign in success
      final headers = response.headers;
      final cookies = headers['set-cookie'];
      final accessToken = cookies?.firstWhere(
        (element) => element.startsWith('${_config.serverSessionCookieName}='),
        orElse: () => '',
      );
      if (accessToken == null || accessToken.isEmpty) {
        return SignInResponse(
          error: SignInError(
            code: SignInErrorCode.serverError,
            exception: SignInException(
              'access token not found in the response headers',
            ),
          ),
          status: 500,
          ok: false,
        );
      }

      final accessTokenValue = _parseCookieValue(accessToken);
      final accesssTokenExpiresAt = _parseCookieExpiration(accessToken);
      await _tokenCache.setAccessToken(
        accessTokenValue,
        expiresAt: accesssTokenExpiresAt,
      );

      // cache csrf token
      await _cacheCSRFCookieFromHeaders(response);

      return SignInResponse(ok: true, status: 200);
    } else {
      if (url != null && url.isNotEmpty) {
        try {
          final responseUrl = Uri.parse(url);
          final error = responseUrl.queryParameters['error'];
          if (error != null && error.isNotEmpty) {
            return SignInResponse(
              error: SignInError(
                code: SignInErrorCode.invalidLogin,
                exception: SignInException(error),
              ),
              status: response.statusCode ?? 500,
              ok: false,
            );
          }
        } catch (_) {}
      }
    }

    return SignInResponse(
      error: SignInError(
        code: SignInErrorCode.serverError,
        exception: SignInException(
          'login failed and the callback url does not contain error parameter',
        ),
      ),
      status: 500,
      ok: false,
    );
  }

  Future<SignInResponse> _handleOAuthSignInResponse(
    HttpResponse response,
  ) async {
    final body = response.body;
    if (body == null) {
      return SignInResponse(
        error: SignInError(
          code: SignInErrorCode.serverError,
          exception: SignInException('body data of the OAuth response is null'),
        ),
        status: 500,
        ok: false,
      );
    }

    final apiResult = _parseApiResult(body);
    if (apiResult.error != 0) {
      return SignInResponse(
        error: SignInError(
          code: SignInErrorCode.invalidLogin,
          exception: SignInException(
            apiResult.message ?? "oauth.error-authentication-failed",
          ),
        ),
        status: apiResult.error,
        ok: false,
      );
    }

    final token = apiResult.data?['accessToken'] as String?;
    assert(token != null, 'accessToken is required');

    // cache access token
    await _tokenCache.setAccessToken(token);

    // cache refresh token (set null to delete if not present)
    final refreshToken = apiResult.data?['refreshToken'] as String?;
    final refreshTokenExpiresAt =
        apiResult.data?['refreshTokenExpiresAt'] as int?;
    await _tokenCache.setRefreshToken(
      refreshToken,
      expiresAt: refreshTokenExpiresAt,
    );

    // cache csrf token
    await _cacheCSRFCookieFromHeaders(response);

    return SignInResponse(ok: true, status: 200);
  }

  ({int error, String? message, ReturnData? data}) _parseApiResult<
    ReturnData extends Map<String, dynamic>
  >(Map<String, dynamic> body) {
    final errorValue = body['error'] as int;
    return (
      error: errorValue,
      message: body['message'] as String?,
      data: errorValue == 0 ? body['data'] as ReturnData? : null,
    );
  }

  Future<void> signOut() async {
    try {
      final url = apiBaseUrl(_config.domain, _config.authBasePath, 'signout');

      await _config.httpClient.post(
        url,
        body: {'csrfToken': await getCSRFToken()},
        options: HttpClientOptions(
          contentType: 'application/x-www-form-urlencoded',
          responseType: HttpClientResponseType.plain,
          cookies: await _getCookieList(attachAccessToken: true),
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
    } catch (e) {
      logger?.error('signOut error', e);
    } finally {
      await _tokenCache.clearAll();
    }
  }

  /// Update session data
  Future<T?> updateSession(Map<String, dynamic> data) async {
    try {
      final url = apiBaseUrl(_config.domain, _config.authBasePath, 'session');

      final response = await _config.httpClient.post(
        url,
        options: HttpClientOptions(
          contentType: 'application/json',
          cookies: await _getCookieList(attachAccessToken: true),
        ),
        body: {'csrfToken': await getCSRFToken(), 'data': data},
      );

      final body = response.body;
      if (body != null && body is Map<String, dynamic> && body.isNotEmpty) {
        await _cacheCSRFCookieFromHeaders(response);
        return _config.sessionSerializer.fromJson(body);
      }

      return null;
    } catch (e) {
      logger?.error('updateSession error', e);
      return null;
    }
  }

  /// request CSRF token from server
  Future<String?> getCSRFToken({bool forceNew = false}) async {
    // 1, get from cache first
    if (!forceNew) {
      final cachedToken = await _tokenCache.getCSRFToken();
      if (cachedToken != null && cachedToken.isNotEmpty) {
        return cachedToken;
      }
    }

    // 2, if no cache, fetch from server then cache it
    try {
      final url = apiBaseUrl(_config.domain, _config.authBasePath, 'csrf');

      final response = await _config.httpClient.get(
        url,
        options: HttpClientOptions(contentType: 'application/json'),
      );
      await _cacheCSRFCookieFromHeaders(response);

      return await _tokenCache.getCSRFToken();
    } catch (e) {
      logger?.error('getCSRFToken error', e);
      return null;
    }
  }

  /// get session data from server
  Future<T?> getSession() async {
    try {
      final url = apiBaseUrl(_config.domain, _config.authBasePath, 'session');

      final response = await _config.httpClient.get(
        url,
        options: HttpClientOptions(
          contentType: 'application/json',
          cookies: await _getCookieList(attachAccessToken: true),
        ),
      );

      final body = response.body;
      if (body != null && body is Map<String, dynamic> && body.isNotEmpty) {
        await _cacheCSRFCookieFromHeaders(response);
        return _config.sessionSerializer.fromJson(body);
      }

      return null;
    } catch (e) {
      logger?.error('getSession error', e);
      return null;
    }
  }
}
