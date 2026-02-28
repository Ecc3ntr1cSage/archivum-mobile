import 'package:flutter/material.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/snippets/presentation/snippets_page.dart';
import '../features/accounts/presentation/accounts_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/solat/presentation/solat_page.dart';
import '../features/finance/presentation/finance_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 2; // Home in center

  final List<Widget> _pages = const [
    SnippetsPage(),
    AccountsPage(),
    HomePage(),
    SolatPage(),
    FinancePage(),
  ];

  void _onTap(int idx) => setState(() => _currentIndex = idx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivum'),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
