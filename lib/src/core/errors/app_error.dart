abstract class AppError {
  final String message;
  AppError(this.message);
}

class NetworkError extends AppError {
  NetworkError(String message) : super(message);
}

class AuthError extends AppError {
  AuthError(String message) : super(message);
}

class UnknownError extends AppError {
  UnknownError(String message) : super(message);
}
