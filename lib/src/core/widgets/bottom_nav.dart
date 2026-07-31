import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isActionOpen = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isActionOpen;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Almanac'),
    _NavItem(icon: Icons.add_rounded, label: 'Add', isAction: true),
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'Prayer'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final railColor = Color.lerp(theme.sidebar, const Color(0xFF27253A), 0.72)!;
    final railBorder = Color.lerp(theme.border, const Color(0xFF3A3552), 0.65)!;

    return Container(
      margin: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: railColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: railBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: railColor.withValues(alpha: 0.58),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          if (item.isAction) {
            return _ActionButton(
              theme: theme,
              isOpen: isActionOpen,
              onTap: () => onTap(i),
            );
          }

          return Expanded(
            child: _NavButton(
              icon: item.icon,
              label: item.label,
              isSelected: i == currentIndex,
              theme: theme,
              onTap: () => onTap(i),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isAction = false,
  });

  final IconData icon;
  final String label;
  final bool isAction;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final ArchivumTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Color.lerp(
      theme.primary,
      const Color(0xFFFF4D92),
      0.38,
    )!;
    final idleColor = Color.lerp(
      theme.mutedForeground,
      const Color(0xFFA39AB9),
      0.4,
    )!;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: double.infinity,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: isSelected
                    ? Border.all(color: activeColor.withValues(alpha: 0.28))
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.34),
                          blurRadius: 18,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : idleColor,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.theme,
    required this.isOpen,
    required this.onTap,
  });

  final ArchivumTheme theme;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final buttonColor = Color.lerp(
      theme.sidebar,
      const Color(0xFF2E2B43),
      0.78,
    )!;
    final buttonBorder = Color.lerp(
      theme.border,
      const Color(0xFF5B5578),
      isOpen ? 0.92 : 0.72,
    )!;
    final iconColor = Color.lerp(
      theme.mutedForeground,
      theme.primary,
      isOpen ? 0.78 : 0.28,
    )!;

    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Tooltip(
            message: 'Add',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: buttonColor,
                border: Border.all(
                  color: buttonBorder,
                  width: isOpen ? 1.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isOpen ? 0.24 : 0.18),
                    blurRadius: isOpen ? 20 : 14,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: theme.primary.withValues(
                      alpha: isOpen ? 0.18 : 0.08,
                    ),
                    blurRadius: isOpen ? 18 : 10,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  isOpen ? Icons.close_rounded : Icons.add_rounded,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
