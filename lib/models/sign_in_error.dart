enum SignInErrorCode {
  networkError,
  invalidLogin,
  serverError,
}

class SignInError {
  final SignInErrorCode code;
  final Exception? exception;

  SignInError({required this.code, this.exception});
}
