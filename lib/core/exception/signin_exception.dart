class SignInException implements Exception {
  final String message;
  SignInException(this.message);

  @override
  String toString() => 'SignInException: $message';

  factory SignInException.fromObject(Object e) {
    if (e is SignInException) return e;
    return SignInException(e.toString());
  }
}
