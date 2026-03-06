import 'package:flutter/material.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/snippets/presentation/snippets_page.dart';
import '../features/accounts/presentation/accounts_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/prayers/presentation/prayer_page.dart';
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
    PrayerPage(),
    FinancePage(),
  ];

  void _onTap(int idx) => setState(() => _currentIndex = idx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the scaffold's own bottom nav — we position it manually
      body: Stack(
        children: [
          // ── Page content ──────────────────────────────────────────────
          Positioned.fill(
            child: _pages[_currentIndex],
          ),

          // ── Floating bottom nav bar ───────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: BottomNav(
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
