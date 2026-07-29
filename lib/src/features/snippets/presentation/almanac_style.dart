import 'package:flutter/material.dart';

class AlmanacColors {
  static const background = Color(0xFF0A0A12);
  static const surface = Color(0xFF141422);
  static const surfaceLow = Color(0xFF111118);
  static const surfaceHigh = Color(0xFF1E1E30);
  static const surfaceHighest = Color(0xFF28283E);
  static const primary = Color(0xFFFF2D78);
  static const primarySoft = Color(0xFFFF80AA);
  static const secondary = Color(0xFF00FFCC);
  static const tertiary = Color(0xFFFFE04A);
  static const foreground = Color(0xFFE8E0F0);
  static const muted = Color(0xFFA098B0);
  static const outline = Color(0xFF302840);
  static const error = Color(0xFFFF4444);
  static const grid = Color(0x1EFFFFFF);
}

class AlmanacBackdrop extends StatelessWidget {
  const AlmanacBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AlmanacColors.background,
        gradient: RadialGradient(
          center: const Alignment(-0.8, -1.0),
          radius: 1.0,
          colors: [
            AlmanacColors.primary.withValues(alpha: 0.09),
            AlmanacColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: const CustomPaint(painter: AlmanacGridPainter()),
    );
  }
}

class AlmanacGridPainter extends CustomPainter {
  const AlmanacGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlmanacColors.grid
      ..strokeWidth = 1;
    const gap = 36.0;

    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AlmanacPanel extends StatelessWidget {
  const AlmanacPanel({
    required this.child,
    required this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
    super.key,
  });

  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AlmanacColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AlmanacButtonPanel extends StatelessWidget {
  const AlmanacButtonPanel({
    required this.child,
    required this.onTap,
    required this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AlmanacPanel(
          borderColor: borderColor,
          padding: padding,
          radius: radius,
          child: child,
        ),
      ),
    );
  }
}

class AlmanacTopBar extends StatelessWidget {
  const AlmanacTopBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          leading ??
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AlmanacColors.surfaceHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AlmanacColors.primary.withValues(alpha: 0.38),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AlmanacColors.primarySoft,
                  size: 22,
                ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AlmanacColors.primarySoft,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: AlmanacColors.primary, blurRadius: 8),
                    ],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AlmanacColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class AlmanacIconButton extends StatelessWidget {
  const AlmanacIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color = AlmanacColors.muted,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        onPressed: onTap,
        color: color,
        style: IconButton.styleFrom(
          backgroundColor: AlmanacColors.surface.withValues(alpha: 0.72),
          side: BorderSide(
            color: AlmanacColors.outline.withValues(alpha: 0.74),
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

InputDecoration almanacInputDecoration(String label, {IconData? prefixIcon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: AlmanacColors.muted, size: 20),
    filled: true,
    fillColor: AlmanacColors.surfaceLow,
    labelStyle: const TextStyle(color: AlmanacColors.muted),
    hintStyle: TextStyle(color: AlmanacColors.muted.withValues(alpha: 0.62)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AlmanacColors.outline.withValues(alpha: 0.72),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AlmanacColors.outline.withValues(alpha: 0.72),
      ),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AlmanacColors.primary, width: 1.5),
    ),
  );
}

ButtonStyle almanacCommitButtonStyle(Color accent) {
  return ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AlmanacColors.surfaceHighest,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    shadowColor: accent.withValues(alpha: 0.42),
    elevation: 10,
  );
}
