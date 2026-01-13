import 'package:flutter_next_auth_core/models/sign_in_error.dart';

/// Response from sign in operation
class SignInResponse {
  /// Error information if sign in failed
  final SignInError? error;
  
  /// HTTP status code
  final int status;
  
  /// Whether the sign in was successful
  final bool ok;

  /// Creates a sign in response
  SignInResponse({this.error, required this.status, required this.ok});
}
