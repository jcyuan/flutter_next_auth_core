import 'package:flutter_next_auth/oauth/oauth_provider.dart';

class OAuthProviderRegistry {
  final Map<String, OAuthProvider> _providers = {};

  void registerOAuthProvider(String providerId, OAuthProvider provider) {
    _providers[providerId] = provider;
  }

  OAuthProvider? getProvider(String providerId) {
    return _providers[providerId];
  }

  bool hasProvider(String providerId) {
    return _providers.containsKey(providerId);
  }

  void removeOAuthProvider(String providerId) {
    _providers.remove(providerId);
  }

  Iterable<OAuthProvider> getOAuthProviders() {
    return _providers.values;
  }
}
