import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/app_error.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/domain/auth_state_provider.dart';
import '../features/auth/presentation/login_page.dart';
import 'shell.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Archivum',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: authStateAsync.when(
        data: (authState) {
          final session = authState.session;
          if (session != null) {
            return const AppShell();
          }
          return const LoginPage();
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) =>
            Scaffold(body: Center(child: Text(AppError.from(error).message))),
      ),
    );
  }
}
