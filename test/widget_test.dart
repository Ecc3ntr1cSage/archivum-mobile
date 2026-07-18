import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:archivum_mobile/src/core/theme/app_theme.dart';
import 'package:archivum_mobile/src/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('App shows the email sign-in screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: lightTheme, home: const LoginPage()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });
}
