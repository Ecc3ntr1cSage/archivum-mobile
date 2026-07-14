import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.article_rounded, label: 'Almanac'),
    _NavItem(icon: Icons.add_rounded, label: 'Add', isAction: true),
    _NavItem(icon: Icons.schedule_rounded, label: 'Prayer'),
    _NavItem(icon: Icons.pie_chart_rounded, label: 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.sidebar,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          if (item.isAction) {
            return _ActionButton(theme: theme, onTap: () => onTap(i));
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? theme.primary : theme.mutedForeground,
                size: 19,
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.theme, required this.onTap});

  final ArchivumTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -13),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Tooltip(
              message: 'Add',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.sidebar, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: theme.secondary.withValues(alpha: 0.34),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: theme.secondaryForeground,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
