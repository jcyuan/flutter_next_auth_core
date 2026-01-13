import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_next_auth_core/core/exception/signin_exception.dart';
import 'package:flutter_next_auth_core/models/sign_in_response.dart';
import 'package:flutter_next_auth_core/cache/token_cache.dart';
import 'package:flutter_next_auth_core/config/next_auth_config.dart';
import 'package:flutter_next_auth_core/events/next_auth_events.dart';
import 'package:flutter_next_auth_core/models/sign_in_error.dart';
import 'package:flutter_next_auth_core/models/sign_in_options.dart';
import 'package:flutter_next_auth_core/models/session_status.dart';
import 'package:flutter_next_auth_core/oauth/oauth_provider.dart';
import 'package:flutter_next_auth_core/oauth/oauth_provider_registry.dart';
import 'package:flutter_next_auth_core/services/auth_service.dart';
import 'package:flutter_next_auth_core/utils/logger.dart';

/// NextAuth client instance
/// Create an instance and use it to manage authentication
class NextAuthClient<T> {
  final NextAuthConfig _config;
  late final AuthService<T> _authService;
  late final OAuthProviderRegistry _oauthRegistry;
  late final EventBus _eventBus;
  late final TokenCache _tokenCache;
  Logger? _logger;

  T? _session;
  SessionStatus _status = SessionStatus.initial;

  bool _initialized = false;

  NextAuthClient(this._config) {
    _oauthRegistry = OAuthProviderRegistry();
    _tokenCache = TokenCache();
    _authService = AuthService<T>(
      config: _config,
      oauthRegistry: _oauthRegistry,
      tokenCache: _tokenCache,
    );
    _logger = _config.logger;
    _eventBus = EventBus();
  }

  /// Initialize session
  /// This method usually will be called automatically by the NextAuthRiverpodScope/NextAuthBlocScope widget so that they
  /// will be able to capture the events fired during initialization
  /// But it can also be called manually
  Future<void> recoverLoginStatusFromCache() async {
    if (_initialized) return;
    // Initialize token cache from storage
    await _tokenCache.initialize();
    // Try to load session on initialization
    final accessToken = await _tokenCache.getAccessToken();
    if (accessToken != null && accessToken.isValid) {
      await _loadSession();
    }
    _initialized = true;
  }

  NextAuthConfig get config => _config;

  /// Setter for status with notification
  set _setStatus(SessionStatus value) {
    if (_status != value) {
      _status = value;
      _eventBus.fire(StatusChangedEvent(_status));
    }
  }

  /// Setter for session with notification
  set _setSession(T? value) {
    if (_session != value) {
      _session = value;
      _eventBus.fire(SessionChangedEvent<T>(_session));
    }
  }

  SessionStatus get status => _status;
  T? get session => _session;

  /// Refetch session from server (for example to refresh local version)
  Future<void> refetchSession() async {
    await _loadSession();
  }

  /// Sign in with email, credentials or OAuth provider<br/>
  /// NOTE: this method must be called in a user interaction context (e.g. button press, tap, etc.)
  Future<SignInResponse> signIn(
    String provider, {
    EmailSignInOptions? emailOptions,
    CredentialsSignInOptions? credentialsOptions,
    OAuthSignInOptions? oauthOptions,
  }) async {
    final response = await _authService.signIn(
      provider,
      emailOptions: emailOptions,
      credentialsOptions: credentialsOptions,
      oauthOptions: oauthOptions,
    );

    if (response.ok) {
      final accessToken = await _tokenCache.getAccessToken();
      if (accessToken != null && accessToken.isValid) {
        _eventBus.fire(SignedInEvent(accessToken));

        // refresh session
        await _loadSession();

        return response;
      } else {
        _logger?.error('Access token not found in signIn response: $response');
        return SignInResponse(
          error: SignInError(
            code: SignInErrorCode.serverError,
            exception: SignInException(
              'access token not found in signIn response',
            ),
          ),
          status: 500,
          ok: false,
        );
      }
    }

    return response;
  }

  Future<void> signOut() async {
    if (_session == null) {
      return;
    }

    await _authService.signOut();
    _oauthRegistry.getOAuthProviders().forEach(
      (provider) => provider.signOut(),
    );
    _setSession = null;
    _setStatus = SessionStatus.unauthenticated;
    _eventBus.fire(SignedOutEvent());
  }

  Future<T?> updateSession(T data) async {
    final updatedSession = await _authService.updateSession(data);
    if (updatedSession != null) {
      _setSession = updatedSession;
    }
    return updatedSession;
  }

  Future<String?> getCSRFToken({bool forceNew = false}) async {
    return await _authService.getCSRFToken(forceNew: forceNew);
  }

  void setLogger(Logger logger) {
    _logger = logger;
  }

  void registerOAuthProvider(String providerId, OAuthProvider provider) {
    _oauthRegistry.registerOAuthProvider(providerId, provider);
  }

  void removeOAuthProvider(String providerId) {
    _oauthRegistry.removeOAuthProvider(providerId);
  }

  EventBus get eventBus => _eventBus;

  Future<void> _loadSession() async {
    _setStatus = SessionStatus.loading;

    try {
      final session = await _authService.getSession();
      _setSession = session;
      _setStatus = session != null
          ? SessionStatus.authenticated
          : SessionStatus.unauthenticated;
    } catch (e) {
      _logger?.error('_loadSession error', e);
      _setSession = null;
      _setStatus = SessionStatus.unauthenticated;
    }
  }
}
