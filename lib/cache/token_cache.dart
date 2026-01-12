import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_next_auth/cache/token.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Internal token cache for storing authentication tokens
/// Uses FlutterSecureStorage for persistent storage
class TokenCache {
  static const String _keyPrefix = '__flutter_next_auth_';
  static const String _csrfCookieKey = '${_keyPrefix}csrf_cookie';
  static const String _refreshTokenKey = '${_keyPrefix}refresh_token';
  static const String _accessTokenKey = '${_keyPrefix}access_token';

  final FlutterSecureStorage _storage;

  String? _csrfToken;
  bool _initialized = false;

  TokenCache({
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
    LinuxOptions? linuxOptions,
    WebOptions? webOptions,
    WindowsOptions? windowsOptions,
  }) : _storage = FlutterSecureStorage(
          aOptions: androidOptions ?? const AndroidOptions(),
          iOptions: iosOptions ?? const IOSOptions(),
          lOptions: linuxOptions ?? const LinuxOptions(),
          webOptions: webOptions ?? const WebOptions(),
          wOptions: windowsOptions ?? const WindowsOptions(),
        );

  /// Initialize cache by loading values from storage
  Future<void> initialize() async {
    if (_initialized) return;
    
    final cookie = await getCSRFCookie();
    if (cookie != null) {
      _csrfToken = _extractCSRFTokenFromCookie(cookie);
    }
    
    _initialized = true;
  }

  /// Extract CSRF token from cookie value
  String? _extractCSRFTokenFromCookie(String cookie) {
    if (cookie.indexOf('|') > 0) {
      return cookie.split('|')[0];
    }
    return cookie;
  }

  /// Get CSRF token from cache
  Future<String?> getCSRFToken() async {
    // Initialize if not already done
    if (!_initialized) {
      debugPrint('[NextAuth::TokenCache] is not initialized yet');
      return null;
    }
    
    // Check if token is still valid in storage
    final cookie = await getCSRFCookie();
    if (cookie != null) {
      return _csrfToken;
    }
    
    return null;
  }

  Future<String?> getCSRFCookie() async {
    // format is "token|hash"
    return (await _getToken(_csrfCookieKey))?.token;
  }

  /// Set CSRF token to cache
  /// If token is null, removes it from cache
  /// [expiresAt] is optional expiration timestamp in milliseconds since epoch
  Future<void> setCSRFCookie(String? cookie, {int? expiresAt}) async {
    if (cookie == null) {
      _csrfToken = null;
      await _setToken(_csrfCookieKey, null, expiresAt: expiresAt);
      return;
    }

    cookie = Uri.decodeComponent(cookie);
    _csrfToken = _extractCSRFTokenFromCookie(cookie);

    await _setToken(_csrfCookieKey, cookie, expiresAt: expiresAt);
  }

  /// Get refresh token from cache
  /// Returns null if token is expired or not found
  Future<Token?> getRefreshToken() async {
    return await _getToken(_refreshTokenKey);
  }

  /// Set refresh token to cache
  /// If token is null, removes it from cache
  /// [expiresAt] is optional expiration timestamp in milliseconds since epoch
  Future<void> setRefreshToken(String? token, {int? expiresAt}) async {
    await _setToken(_refreshTokenKey, token, expiresAt: expiresAt);
  }

  /// Get access token from cache
  /// Returns null if token is expired or not found
  Future<Token?> getAccessToken() async {
    return await _getToken(_accessTokenKey);
  }

  /// Set access token to cache
  /// If token is null, removes it from cache
  /// [expiresAt] is optional expiration timestamp in milliseconds since epoch
  Future<void> setAccessToken(String? token, {int? expiresAt}) async {
    await _setToken(_accessTokenKey, token, expiresAt: expiresAt);
  }

  /// Clear all cached tokens
  Future<void> clearAll() async {
    _csrfToken = null;
    await _storage.delete(key: _csrfCookieKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessTokenKey);
  }

  Future<Token?> _getToken(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;

    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      final tokenString = data['token'] as String?;
      final expiresAt = data['expiresAt'] as int?;

      if (tokenString == null) {
        await _storage.delete(key: key);
        return null;
      }

      final token = Token(
        token: tokenString,
        expiration: expiresAt,
      );

      // Check if token is expired
      if (!token.isValid) {
        await _storage.delete(key: key);
        return null;
      }

      return token;
    } catch (e) {
      await _storage.delete(key: key);
      return null;
    }
  }

  /// Internal method to set token with optional expiration
  Future<void> _setToken(String key, String? token, {int? expiresAt}) async {
    if (token == null) {
      // Remove token if null
      await _storage.delete(key: key);
      return;
    }

    final data = <String, dynamic>{
      'token': token,
    };
    if (expiresAt != null) {
      data['expiresAt'] = expiresAt;
    }

    await _storage.write(key: key, value: jsonEncode(data));
  }
}
