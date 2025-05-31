class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, {this.code = 'authentication-failed'});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

class AdminCreationException extends AuthException {
  AdminCreationException(String message)
      : super(message, code: 'admin-creation-failed');
}
