import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/supabase_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Archivum',
      theme: appTheme,
      home: const Scaffold(
        body: Center(child: Text('Welcome to Archivum')),
      ),
    );
  }
}
