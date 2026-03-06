import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/domain/auth_state_provider.dart';
import '../../agent/presentation/chat_page.dart';
import '../../accounts/presentation/add_credential_page.dart';
import '../../indexes/presentation/add_index_page.dart';
import '../../insights/presentation/insight_page.dart';
import '../../notes/presentation/add_note_page.dart';
import '../../quotes/presentation/add_quote_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF7C4DFF);
const _kSecondary = Color(0xFFFF8A50);
const _kBg        = Color(0xFF0B0B0D);
const _kCard      = Color(0xFF13101C);
const _kBorder    = Color(0xFF251C38);
const _kMuted     = Color(0xFF6B7A8D);

// ─────────────────────────────────────────────────────────────────────────────
// HomePage
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync   = ref.watch(authStateProvider);
    final user        = authAsync.asData?.value.session?.user;
    final displayName = (user?.userMetadata?['full_name'] as String?)
        ?? user?.email?.split('@').first
        ?? 'there';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return ColoredBox(
      color: _kBg,
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

  final String  name;
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
class _TopBar extends StatelessWidget {
  const _TopBar({required this.name, this.avatarUrl});

  final String  name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.8)),
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
                style: TextStyle(
                  color: _kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _capitalise(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          _NavIconBtn(
            icon: Icons.settings_outlined,
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

  final String  name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    const borderColor = _kPrimary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59FF), Color(0xFF5829D4)],
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
  const _NavIconBtn({required this.icon, this.badge = false});

  final IconData icon;
  final bool     badge;

  @override
  Widget build(BuildContext context) {
    Widget btn = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _kCard,
        shape: BoxShape.circle,
        border: Border.all(color: _kBorder),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    );

    if (!badge) return btn;

    return Stack(
      children: [
        btn,
        Positioned(
          top: 7,
          right: 7,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _kSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: _kBg, width: 1.5),
            ),
          ),
        ),
      ],
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
    final now     = DateTime.now();
    final dateStr = DateFormat('EEE, d MMMM').format(now);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Everything looks good for today.',
            style: TextStyle(color: _kMuted, fontSize: 13),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: _kCard,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Archivum AI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: const AgentChatPage(),
        ),
      ),
    );
  }

  void _openInsights(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightPage()));

  void _openAddNote(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNotePage()));

  void _openAddQuote(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddQuotePage()));

  void _openAddIndex(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIndexPage()));

    void _openAddAccounts(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCredentialPage()));

  Future<void> _openDailyDev() async {
    final uri = Uri.parse('https://app.daily.dev');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1 — AI card (gradient) + Insights
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AiCard(onTap: () => _openAgent(context))),
              const SizedBox(width: 12),
              Expanded(child: _InsightsCard(onTap: () => _openInsights(context))),
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
                bgColor: _kPrimary,
                onTap: () => _openAddNote(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAddCard(
                label: 'Add Quote',
                icon: Icons.format_quote_rounded,
                bgColor: _kSecondary,
                onTap: () => _openAddQuote(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAddCard(
                label: 'Add Index',
                icon: Icons.list_alt_rounded,
                bgColor: const Color(0xFF1C1430),
                iconColor: _kPrimary,
                onTap: () => _openAddIndex(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 3 — Add Account + daily.dev
        SizedBox(
          height: 96, // Fixed height to make it slightly taller than squares
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AddAccountCard(onTap: () => _openAddAccounts(context))),
              const SizedBox(width: 12),
              Expanded(child: _DailyDevCard(onTap: _openDailyDev)),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8F30F0), Color(0xFF3B1588)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
            const Spacer(),
            const Text(
              'Archivum AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Summarize your day',
              style: TextStyle(
                color: Color(0xFFD4ADFF),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: _kSecondary,
                size: 22,
              ),
            ),
            const Spacer(),
            const Text(
              'Insights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'View trends',
              style: TextStyle(color: _kMuted, fontSize: 12),
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
    this.iconColor,
    required this.onTap,
  });

  final String     label;
  final IconData   icon;
  final Color      bgColor;
  final Color?     iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = iconColor != null; // "dark" card variant uses iconColor
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: _kBorder) : null,
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
                      ? _kPrimary.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark ? iconColor : Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
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
class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: const Icon(
                Icons.add_moderator_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'NEW ACCOUNT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Secure your keys',
                    style: TextStyle(color: _kMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _kPrimary.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── daily.dev card ───────────────────────────────────────────────────────────
class _DailyDevCard extends StatelessWidget {
  const _DailyDevCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0F19),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1C2233)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.terminal_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'daily.dev',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Dev news & feeds',
                    style: TextStyle(color: _kMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: Colors.white30,
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
class _ActivityTracker extends StatelessWidget {
  const _ActivityTracker();

  static const _data   = [8.0, 12.0, 9.0, 16.0, 11.0, 19.0, 14.0];
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final total = _data.reduce((a, b) => a + b).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Tracker',
                    style: TextStyle(color: _kMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$total entries this week',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Last 7 days',
                  style: TextStyle(
                    color: _kPrimary,
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
              painter: _ChartPainter(data: _data),
              child: const SizedBox.expand(),
            ),
          ),

          const SizedBox(height: 10),

          // ── Day labels ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _labels
                .map(
                  (l) => Text(
                    l,
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Chart painter ────────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.data});

  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final step   = size.width / (data.length - 1);
    const pad    = 0.08; // vertical padding ratio

    final pts = List<Offset>.generate(data.length, (i) {
      final x = i * step;
      final y = size.height * pad +
          (1 - data[i] / maxVal) * size.height * (1 - pad * 2);
      return Offset(x, y);
    });

    // ── Smooth bezier curve ──────────────────────────────────────────
    final curvePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final midX = (pts[i].dx + pts[i + 1].dx) / 2;
      curvePath.cubicTo(
        midX, pts[i].dy,
        midX, pts[i + 1].dy,
        pts[i + 1].dx, pts[i + 1].dy,
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
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x5E7C4DFF), Color(0x007C4DFF)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // ── Line stroke ──────────────────────────────────────────────────
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = const Color(0xFF7C4DFF)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── Data-point dots ──────────────────────────────────────────────
    final outerDot = Paint()..color = const Color(0xFF7C4DFF);
    final innerDot = Paint()..color = _kCard;

    for (final pt in pts) {
      canvas.drawCircle(pt, 4.5, outerDot);
      canvas.drawCircle(pt, 2.2, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.data != data;
}
