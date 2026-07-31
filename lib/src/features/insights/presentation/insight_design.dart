import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

const _insightCurve = Cubic(0.32, 0.72, 0, 1);

class InsightPalette {
  const InsightPalette({required this.isDark, required this.theme});

  final bool isDark;
  final ArchivumTheme theme;

  Color get background =>
      isDark ? const Color(0xFF101011) : const Color(0xFFF8F5EF);
  Color get surface =>
      isDark ? const Color(0xFF181719) : const Color(0xFFFFFCF7);
  Color get surfaceRaised =>
      isDark ? const Color(0xFF211F20) : const Color(0xFFFFFFFF);
  Color get shell => isDark
      ? Colors.white.withValues(alpha: 0.045)
      : Colors.black.withValues(alpha: 0.035);
  Color get ink => isDark ? const Color(0xFFF4EFE8) : const Color(0xFF26221F);
  Color get muted => isDark ? const Color(0xFFA9A29B) : const Color(0xFF7F766D);
  Color get hairline => isDark
      ? Colors.white.withValues(alpha: 0.1)
      : Colors.black.withValues(alpha: 0.08);
  Color get ember => theme.primary;
  Color get sage => theme.secondary;
  Color get blush => isDark ? const Color(0xFF6A4235) : const Color(0xFFF3E1D2);
  Color get mint => isDark ? const Color(0xFF24413E) : const Color(0xFFDCEAE3);

  static InsightPalette of(BuildContext context) {
    final theme = context.archivumTheme;
    return InsightPalette(
      isDark: Theme.of(context).brightness == Brightness.dark,
      theme: theme,
    );
  }
}

class InsightReveal extends StatelessWidget {
  const InsightReveal({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 620 + (index * 55)),
      curve: _insightCurve,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class InsightTopBar extends StatelessWidget {
  const InsightTopBar({
    required this.palette,
    required this.title,
    required this.onBack,
    required this.onRefresh,
    super.key,
  });

  final InsightPalette palette;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InsightIconButton(
          palette: palette,
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
          tooltip: 'Back',
        ),
        Text(
          title,
          style: TextStyle(
            color: palette.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        InsightIconButton(
          palette: palette,
          icon: Icons.refresh_rounded,
          onTap: onRefresh,
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

class InsightIconButton extends StatelessWidget {
  const InsightIconButton({
    required this.palette,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    super.key,
  });

  final InsightPalette palette;
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.hairline),
            ),
            child: Icon(icon, color: palette.ink, size: 18),
          ),
        ),
      ),
    );
  }
}

class InsightEyebrow extends StatelessWidget {
  const InsightEyebrow({required this.label, required this.palette, super.key});

  final String label;
  final InsightPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.blush,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.ember,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class InsightSurface extends StatelessWidget {
  const InsightSurface({
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(5),
    super.key,
  });

  final InsightPalette palette;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.shell,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: palette.isDark ? 0.14 : 0.045,
            ),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: palette.isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
        child: child,
      ),
    );
  }
}

class InsightSectionHeader extends StatelessWidget {
  const InsightSectionHeader({
    required this.palette,
    required this.eyebrow,
    required this.title,
    required this.icon,
    super.key,
  });

  final InsightPalette palette;
  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 21,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        Icon(icon, color: palette.ember, size: 21),
      ],
    );
  }
}

class InsightMetricTile extends StatelessWidget {
  const InsightMetricTile({
    required this.palette,
    required this.label,
    required this.value,
    required this.accent,
    this.icon,
    super.key,
  });

  final InsightPalette palette;
  final String label;
  final String value;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: palette.isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: 16),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightPill extends StatelessWidget {
  const InsightPill({
    required this.palette,
    required this.label,
    required this.color,
    super.key,
  });

  final InsightPalette palette;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightListRow extends StatelessWidget {
  const InsightListRow({
    required this.palette,
    required this.label,
    required this.value,
    required this.accent,
    super.key,
  });

  final InsightPalette palette;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightEmptyState extends StatelessWidget {
  const InsightEmptyState({
    required this.palette,
    required this.label,
    super.key,
  });

  final InsightPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: palette.muted, fontSize: 13, height: 1.4),
    );
  }
}
