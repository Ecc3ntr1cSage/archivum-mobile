import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppErrorKind {
  auth,
  network,
  validation,
  notFound,
  permission,
  config,
  database,
  unknown,
}

/// The only error type that should cross a data/service boundary.
class AppError implements Exception {
  const AppError({
    required this.kind,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final AppErrorKind kind;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  factory AppError.auth(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
  }) => AppError(
    kind: AppErrorKind.auth,
    message: message,
    cause: cause,
    stackTrace: stackTrace,
  );

  factory AppError.validation(String message) =>
      AppError(kind: AppErrorKind.validation, message: message);

  factory AppError.config(String message) =>
      AppError(kind: AppErrorKind.config, message: message);

  factory AppError.network(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
  }) => AppError(
    kind: AppErrorKind.network,
    message: message,
    cause: cause,
    stackTrace: stackTrace,
  );

  factory AppError.from(Object error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;
    final trace = stackTrace ?? StackTrace.current;

    if (error is AuthException) {
      return AppError.auth(
        _authMessage(error),
        cause: error,
        stackTrace: trace,
      );
    }
    if (error is PostgrestException) {
      final kind = error.code == '42501'
          ? AppErrorKind.permission
          : error.code == 'PGRST116'
          ? AppErrorKind.notFound
          : AppErrorKind.database;
      return AppError(
        kind: kind,
        message: _backendMessage(error.message),
        cause: error,
        stackTrace: trace,
      );
    }
    if (error is http.ClientException ||
        error is SocketException ||
        error is TimeoutException) {
      return AppError(
        kind: AppErrorKind.network,
        message: 'Check your connection and try again.',
        cause: error,
        stackTrace: trace,
      );
    }

    return AppError(
      kind: AppErrorKind.unknown,
      message: 'Something went wrong. Please try again.',
      cause: error,
      stackTrace: trace,
    );
  }

  static String _authMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email or password is incorrect.';
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    return 'Authentication failed. Please try again.';
  }

  static String _backendMessage(String message) {
    if (message.toLowerCase().contains('duplicate')) {
      return 'This record already exists.';
    }
    return 'We could not complete that request. Please try again.';
  }

  @override
  String toString() => message;
}

String errorMessage(Object error) => AppError.from(error).message;
