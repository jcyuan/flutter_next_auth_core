import 'package:flutter_next_auth/models/sign_in_error.dart';

class SignInResponse {
  final SignInError? error;
  final int status;
  final bool ok;

  SignInResponse({
    this.error,
    required this.status,
    required this.ok,
  });
}
