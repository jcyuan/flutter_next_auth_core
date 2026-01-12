import 'dart:convert';

class Token {
  final String token;
  /// expiration timestamp in milliseconds since epoch
  final int? expiration;

  const Token({
    required this.token,
    this.expiration,
  });

  bool get isExpired {
    if (expiration == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= expiration!;
  }
  
  bool get isValid {
    return !isExpired && token.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiration': expiration,
    };
  }

  static Token? fromJsonString(String? tokenJsonString) {
    if (tokenJsonString == null || tokenJsonString.isEmpty) return null;
    try {
      Object? data = jsonDecode(tokenJsonString);
      if (data is Map<String, dynamic> && data.containsKey('token') && data.containsKey('expiration')) {
        final token = data['token'] as String?;
        final expiration = data['expiration'] as int?;
        if (token != null && token.isNotEmpty) {
          return Token(
            token: token,
            expiration: expiration
          );
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
