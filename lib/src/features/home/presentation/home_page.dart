import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/activity_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';

import '../../auth/domain/auth_state_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../agent/presentation/chat_page.dart';
import '../../accounts/presentation/add_credential_page.dart';
import '../../indexes/presentation/add_index_page.dart';
import '../../insights/presentation/insight_page.dart';
import '../../notes/presentation/add_note_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// HomePage
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.archivumTheme;
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value.session?.user;
    final displayName =
        (user?.userMetadata?['full_name'] as String?) ??
        user?.email?.split('@').first ??
        'there';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return ColoredBox(
      color: theme.background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Sticky top bar ────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _TopBarDelegate(
                name: displayName,
                avatarUrl: avatarUrl,
              ),
            ),
            // ── Scrollable body ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _DateBanner(),
                    SizedBox(height: 22),
                    _BentoGrid(),
                    SizedBox(height: 28),
                    _ActivityTracker(),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky top-bar via SliverPersistentHeader
// ─────────────────────────────────────────────────────────────────────────────
class _TopBarDelegate extends SliverPersistentHeaderDelegate {
  const _TopBarDelegate({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  static const _height = 72.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_TopBarDelegate old) =>
      old.name != name || old.avatarUrl != avatarUrl;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _TopBar(name: name, avatarUrl: avatarUrl);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar widget
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.archivumTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(bottom: BorderSide(color: theme.border, width: 0.8)),
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────────
          _Avatar(name: name, avatarUrl: avatarUrl),
          const SizedBox(width: 12),
          // ── Greeting ────────────────────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Text(
                _capitalise(name),
                style: TextStyle(
                  color: theme.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          _NavIconBtn(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onTap: () =>
                ref.read(themeControllerProvider.notifier).toggle(isDark),
          ),
          const SizedBox(width: 8),
          _NavIconBtn(
            icon: Icons.logout_rounded,
            tooltip: 'Sign out',
            onTap: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not sign out: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.primary, width: 2),
        gradient: LinearGradient(
          colors: [theme.primary, theme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, err, st) => _initials(),
              ),
            )
          : _initials(),
    );
  }

  Widget _initials() => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'A',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    ),
  );
}

// ─── Small nav icon button ────────────────────────────────────────────────────
class _NavIconBtn extends StatelessWidget {
  const _NavIconBtn({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.card,
            shape: BoxShape.circle,
            border: Border.all(color: theme.border),
          ),
          child: Icon(
            icon,
            color: theme.foreground.withValues(alpha: 0.72),
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date banner
// ─────────────────────────────────────────────────────────────────────────────
class _DateBanner extends StatelessWidget {
  const _DateBanner();

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMMM').format(now);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Everything looks good for today.',
            style: TextStyle(color: theme.mutedForeground, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento grid
// ─────────────────────────────────────────────────────────────────────────────
class _BentoGrid extends StatelessWidget {
  const _BentoGrid();

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _openAgent(BuildContext context) {
    final theme = context.archivumTheme;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.card,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Archivum AI',
              style: TextStyle(
                color: theme.foreground,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            iconTheme: IconThemeData(color: theme.foreground),
          ),
          body: const AgentChatPage(),
        ),
      ),
    );
  }

  void _openInsights(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const InsightPage()),
  );

  void _openAddNote(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddNotePage()),
  );

  void _openAddIndex(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddIndexPage()),
  );

  void _openAddAccounts(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddCredentialPage()),
  );

  Future<void> _openDailyDev() async {
    final uri = Uri.parse('https://app.daily.dev');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Column(
      children: [
        // Row 1 — AI card (gradient) + Insights
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AiCard(onTap: () => _openAgent(context))),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightsCard(onTap: () => _openInsights(context)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Row 2 — Quick-add squares
        Row(
          children: [
            Expanded(
              child: _QuickAddCard(
                label: 'Add Note',
                icon: Icons.edit_note_rounded,
                bgColor: theme.primary,
                fgColor: theme.primaryForeground,
                onTap: () => _openAddNote(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAddCard(
                label: 'Add Account',
                icon: Icons.add_moderator_rounded,
                bgColor: theme.secondary,
                fgColor: theme.secondaryForeground,
                onTap: () => _openAddAccounts(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAddCard(
                label: 'Add Index',
                icon: Icons.list_alt_rounded,
                bgColor: theme.accent,
                fgColor: theme.accentForeground,
                iconColor: theme.primary,
                onTap: () => _openAddIndex(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 3 — Add Account + daily.dev
        SizedBox(
          height: 96, // Fixed height to make it slightly taller than squares
          child: _DailyDevCard(onTap: _openDailyDev),
        ),
      ],
    );
  }
}

// ─── AI card ──────────────────────────────────────────────────────────────────
class _AiCard extends StatelessWidget {
  const _AiCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primary, theme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.primaryForeground,
              size: 28,
            ),
            const Spacer(),
            Text(
              'Archivum AI',
              style: TextStyle(
                color: theme.primaryForeground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Summarize your day',
              style: TextStyle(
                color: theme.primaryForeground.withValues(alpha: 0.72),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Insights card ────────────────────────────────────────────────────────────
class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.insights_rounded,
                color: theme.secondary,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              'Insights',
              style: TextStyle(
                color: theme.cardForeground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'View trends',
              style: TextStyle(color: theme.mutedForeground, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick-add square card ────────────────────────────────────────────────────
class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = iconColor != null; // "dark" card variant uses iconColor
    final theme = context.archivumTheme;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: theme.border) : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.primary.withValues(alpha: 0.18)
                      : fgColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor ?? fgColor),
              ),
              const Spacer(),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: fgColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add Account card ─────────────────────────────────────────────────────────
// ─── daily.dev card ───────────────────────────────────────────────────────────
class _DailyDevCard extends StatelessWidget {
  const _DailyDevCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: theme.muted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.foreground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.terminal_rounded,
                color: theme.background,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'daily.dev',
                    style: TextStyle(
                      color: theme.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Dev news & feeds',
                    style: TextStyle(
                      color: theme.mutedForeground,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: theme.mutedForeground,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Tracker
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityTracker extends ConsumerWidget {
  const _ActivityTracker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.archivumTheme;
    final activityAsync = ref.watch(activityLast7DaysProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: activityAsync.when(
        loading: () => _buildShimmer(theme),
        error: (error, _) => _buildError(ref, theme),
        data: (days) => _buildChart(days, theme),
      ),
    );
  }

  Widget _buildShimmer(ArchivumTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: theme.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 180,
          height: 20,
          decoration: BoxDecoration(
            color: theme.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 120,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(WidgetRef ref, ArchivumTheme theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: theme.mutedForeground, size: 32),
        const SizedBox(height: 8),
        Text(
          'Could not load activity',
          style: TextStyle(color: theme.mutedForeground, fontSize: 12),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => ref.invalidate(activityLast7DaysProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                color: theme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<ActivityDay> days, ArchivumTheme theme) {
    final data = days.map((d) => d.total.toDouble()).toList();
    final labels = days
        .map((d) => DateFormat('E').format(d.day).substring(0, 3))
        .toList();
    final total = days.fold<int>(0, (sum, d) => sum + d.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Tracker',
                  style: TextStyle(color: theme.mutedForeground, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total entries this week',
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Last 7 days',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ── Chart ──────────────────────────────────────────────────────
        SizedBox(
          height: 120,
          child: CustomPaint(
            painter: _ChartPainter(
              data: data,
              lineColor: theme.primary,
              fillColor: theme.primary.withValues(alpha: 0.32),
              cardColor: theme.card,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        const SizedBox(height: 10),

        // ── Day labels ─────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (l) => Text(
                  l,
                  style: TextStyle(
                    color: theme.mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─── Chart painter ────────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  const _ChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.cardColor,
  });

  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final Color cardColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final step = size.width / (data.length - 1);
    const pad = 0.08; // vertical padding ratio

    final pts = List<Offset>.generate(data.length, (i) {
      final x = i * step;
      final ratio = maxVal == 0 ? 0.5 : data[i] / maxVal;
      final y = size.height * pad + (1 - ratio) * size.height * (1 - pad * 2);
      return Offset(x, y);
    });

    // ── Smooth bezier curve ──────────────────────────────────────────
    final curvePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final midX = (pts[i].dx + pts[i + 1].dx) / 2;
      curvePath.cubicTo(
        midX,
        pts[i].dy,
        midX,
        pts[i + 1].dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }

    // ── Gradient fill ────────────────────────────────────────────────
    final fillPath = Path.from(curvePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // ── Line stroke ──────────────────────────────────────────────────
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── Data-point dots ──────────────────────────────────────────────
    final outerDot = Paint()..color = lineColor;
    final innerDot = Paint()..color = cardColor;

    for (final pt in pts) {
      canvas.drawCircle(pt, 4.5, outerDot);
      canvas.drawCircle(pt, 2.2, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.data != data ||
      old.lineColor != lineColor ||
      old.fillColor != fillColor ||
      old.cardColor != cardColor;
}
