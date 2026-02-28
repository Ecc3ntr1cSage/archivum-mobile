abstract class AppError {
  final String message;
  AppError(this.message);
}

class NetworkError extends AppError {
  NetworkError(super.message);
}

class AuthError extends AppError {
  AuthError(super.message);
}

class UnknownError extends AppError {
  UnknownError(super.message);
}
