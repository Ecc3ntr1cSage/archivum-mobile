import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:archivum_mobile/src/core/errors/app_error.dart';

void main() {
  test('preserves standardized errors', () {
    final error = AppError.validation('Title is required.');

    expect(AppError.from(error), same(error));
    expect(error.kind, AppErrorKind.validation);
    expect(error.toString(), 'Title is required.');
  });

  test('maps network failures to a safe user message', () {
    final error = AppError.from(
      const SocketException('private transport detail'),
    );

    expect(error.kind, AppErrorKind.network);
    expect(error.message, 'Check your connection and try again.');
    expect(error.message, isNot(contains('private transport detail')));
  });

  test('maps unknown failures without exposing implementation details', () {
    final error = AppError.from(StateError('database internals'));

    expect(error.kind, AppErrorKind.unknown);
    expect(error.message, 'Something went wrong. Please try again.');
    expect(errorMessage(StateError('database internals')), error.message);
  });
}
