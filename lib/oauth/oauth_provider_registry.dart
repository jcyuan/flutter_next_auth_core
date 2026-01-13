import 'package:flutter_next_auth_core/oauth/oauth_provider.dart';

/// Registry for managing OAuth providers
class OAuthProviderRegistry {
  final Map<String, OAuthProvider> _providers = {};

  /// Registers an OAuth provider
  void registerOAuthProvider(String providerId, OAuthProvider provider) {
    _providers[providerId] = provider;
  }

  /// Gets an OAuth provider by ID
  OAuthProvider? getProvider(String providerId) {
    return _providers[providerId];
  }

  /// Checks if a provider is registered
  bool hasProvider(String providerId) {
    return _providers.containsKey(providerId);
  }

  /// Removes an OAuth provider
  void removeOAuthProvider(String providerId) {
    _providers.remove(providerId);
  }

  /// Gets all registered OAuth providers
  Iterable<OAuthProvider> getOAuthProviders() {
    return _providers.values;
  }
}
