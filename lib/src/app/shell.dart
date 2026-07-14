import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/accounts/presentation/add_credential_page.dart';
import '../features/finance/presentation/finance_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/indexes/presentation/add_index_page.dart';
import '../features/notes/presentation/add_note_page.dart';
import '../features/prayers/presentation/prayer_page.dart';
import '../features/snippets/presentation/snippets_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _isAddMenuOpen = false;

  final List<Widget> _pages = const [
    HomePage(),
    SnippetsPage(),
    SizedBox.shrink(),
    PrayerPage(),
    FinancePage(),
  ];

  void _onTap(int idx) {
    if (idx == 2) {
      setState(() => _isAddMenuOpen = !_isAddMenuOpen);
      return;
    }

    setState(() {
      _currentIndex = idx;
      _isAddMenuOpen = false;
    });
  }

  void _openAddPage(Widget page) {
    setState(() => _isAddMenuOpen = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _goToTab(int idx) {
    setState(() {
      _currentIndex = idx;
      _isAddMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _pages[_currentIndex]),
          if (_isAddMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _isAddMenuOpen = false),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 82,
            child: IgnorePointer(
              ignoring: !_isAddMenuOpen,
              child: _FloatingAddMenu(
                isOpen: _isAddMenuOpen,
                onAddNote: () => _openAddPage(const AddNotePage()),
                onAddIndex: () => _openAddPage(const AddIndexPage()),
                onAddAccount: () => _openAddPage(const AddCredentialPage()),
                onAddPrayer: () => _goToTab(3),
                onAddTransaction: () => _goToTab(4),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: BottomNav(currentIndex: _currentIndex, onTap: _onTap),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAddMenu extends StatelessWidget {
  const _FloatingAddMenu({
    required this.isOpen,
    required this.onAddNote,
    required this.onAddIndex,
    required this.onAddAccount,
    required this.onAddPrayer,
    required this.onAddTransaction,
  });

  final bool isOpen;
  final VoidCallback onAddNote;
  final VoidCallback onAddIndex;
  final VoidCallback onAddAccount;
  final VoidCallback onAddPrayer;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final items = [
      _FloatingAddItem(
        icon: Icons.edit_note_rounded,
        label: 'Add Note',
        onTap: onAddNote,
      ),
      _FloatingAddItem(
        icon: Icons.list_alt_rounded,
        label: 'Add Index',
        onTap: onAddIndex,
      ),
      _FloatingAddItem(
        icon: Icons.shield_outlined,
        label: 'Add Account',
        onTap: onAddAccount,
      ),
      _FloatingAddItem(
        icon: Icons.schedule_rounded,
        label: 'Add Prayer',
        onTap: onAddPrayer,
      ),
      _FloatingAddItem(
        icon: Icons.receipt_long_rounded,
        label: 'Add Transaction',
        onTap: onAddTransaction,
      ),
    ];

    return AnimatedOpacity(
      opacity: isOpen ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: isOpen ? Offset.zero : const Offset(0, 0.12),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _FloatingAddButton(item: items[i], theme: theme),
              if (i != items.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _FloatingAddItem {
  const _FloatingAddItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.item, required this.theme});

  final _FloatingAddItem item;
  final ArchivumTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 208,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.popover,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: theme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: theme.popoverForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
