import 'package:flutter/material.dart';

// ─── Palette (matches home_page.dart) ─────────────────────────────────────────
const _kPrimary = Color(0xFF7C4DFF);
const _kBg = Color(0xFF0B0B0D);
const _kCard = Color(0xFF13101C);
const _kBorder = Color(0xFF251C38);
const _kMuted = Color(0xFF6B7A8D);

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.article_rounded, label: 'Snippets'),
    _NavItem(icon: Icons.shield_rounded, label: 'Accounts'),
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.schedule_rounded, label: 'Prayer'),
    _NavItem(icon: Icons.pie_chart_rounded, label: 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.08),
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
          final isSelected = i == currentIndex;
          return _NavButton(
            icon: item.icon,
            label: item.label,
            isSelected: isSelected,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? _kPrimary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: isSelected ? _kPrimary : _kMuted,
                size: isSelected ? 22 : 20,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
