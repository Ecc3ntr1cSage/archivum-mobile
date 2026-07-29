import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/account_repository_provider.dart';
import '../../../core/providers/activity_provider.dart';
import '../../../core/providers/insight_provider.dart';
import '../../../core/providers/snippet_repository_provider.dart';
import '../../../core/theme/theme_controller.dart';
import '../../accounts/presentation/add_credential_page.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_state_provider.dart';
import '../../indexes/presentation/add_index_page.dart';
import '../../insights/domain/insight_data.dart';
import '../../insights/presentation/insight_page.dart';
import '../../notes/presentation/add_note_page.dart';
import '../../prayers/presentation/prayer_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late DateTime _now;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final insightAsync = ref.watch(insightDataProvider);
    final notesAsync = ref.watch(notesListProvider);
    final indexesAsync = ref.watch(indexesListProvider);
    final accountsAsync = ref.watch(accountsListProvider);

    final user = authAsync.asData?.value.session?.user;
    final displayName =
        (user?.userMetadata?['full_name'] as String?) ??
        user?.email?.split('@').first ??
        'Authorized User';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    final notesCount = notesAsync.asData?.value.length;
    final indexesCount = indexesAsync.asData?.value.length;
    final accountsCount = accountsAsync.asData?.value.length;
    final insight = insightAsync.asData?.value;
    final archiveTotal =
        (notesCount ?? insight?.totalNotes ?? 0) +
        (indexesCount ?? insight?.totalIndexes ?? 0) +
        (accountsCount ?? insight?.totalAccounts ?? 0);

    return Scaffold(
      backgroundColor: _HomeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackdrop()),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TopBarDelegate(
                    name: displayName,
                    avatarUrl: avatarUrl,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 116),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GreetingBlock(now: _now),
                            const SizedBox(height: 16),
                            _DateStatusBanner(
                              now: _now,
                              insight: insight,
                              archiveTotal: archiveTotal,
                              isLoading: insightAsync.isLoading,
                            ),
                            const SizedBox(height: 18),
                            _HomeBento(
                              insight: insight,
                              insightLoading: insightAsync.isLoading,
                              notesCount: notesCount,
                              indexesCount: indexesCount,
                              accountsCount: accountsCount,
                            ),
                            const SizedBox(height: 18),
                            const _ActivityTracker(),
                            const SizedBox(height: 18),
                            _FocusPanel(insight: insight),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeColors {
  static const background = Color(0xFF0A0A12);
  static const surface = Color(0xFF141422);
  static const surfaceHigh = Color(0xFF1E1E30);
  static const surfaceHighest = Color(0xFF28283E);
  static const primary = Color(0xFFFF2D78);
  static const primarySoft = Color(0xFFFF80AA);
  static const secondary = Color(0xFF00FFCC);
  static const tertiary = Color(0xFFFFE04A);
  static const foreground = Color(0xFFE8E0F0);
  static const muted = Color(0xFFA098B0);
  static const outline = Color(0xFF302840);
  static const grid = Color(0x202A2434);
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _HomeColors.background,
        gradient: RadialGradient(
          center: const Alignment(-0.9, 0.95),
          radius: 1.0,
          colors: [
            _HomeColors.secondary.withValues(alpha: 0.06),
            _HomeColors.background.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ),
      ),
      child: const CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _HomeColors.grid
      ..strokeWidth = 1;
    const gap = 40.0;

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

class _TopBarDelegate extends SliverPersistentHeaderDelegate {
  const _TopBarDelegate({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  static const _height = 74.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_TopBarDelegate oldDelegate) {
    return oldDelegate.name != name || oldDelegate.avatarUrl != avatarUrl;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _TopBar(
      name: name,
      avatarUrl: avatarUrl,
      isScrolled: shrinkOffset > 1 || overlapsContent,
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.name,
    required this.avatarUrl,
    required this.isScrolled,
  });

  final String name;
  final String? avatarUrl;
  final bool isScrolled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _HomeColors.background.withValues(
          alpha: isScrolled ? 0.96 : 0.8,
        ),
        border: Border(
          bottom: BorderSide(
            color: _HomeColors.outline.withValues(
              alpha: isScrolled ? 0.82 : 0.42,
            ),
          ),
        ),
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _Avatar(name: name, avatarUrl: avatarUrl),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUTHORIZED USER',
                  style: TextStyle(
                    color: _HomeColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: _HomeColors.secondary, blurRadius: 8),
                    ],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ARCHIVUM',
                  style: TextStyle(
                    color: _HomeColors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            tooltip: isDark ? 'Use light theme' : 'Use dark theme',
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onTap: () =>
                ref.read(themeControllerProvider.notifier).toggle(isDark),
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            tooltip: 'Sign out',
            icon: Icons.logout_rounded,
            onTap: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (error, stackTrace) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not sign out: ${AppError.from(error, stackTrace).message}',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _HomeColors.surfaceHigh,
        border: Border.all(
          color: _HomeColors.primary.withValues(alpha: 0.48),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _HomeColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: avatarUrl == null
          ? _Initials(name: name)
          : ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _Initials(name: name),
              ),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isEmpty ? 'A' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: _HomeColors.primarySoft,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _HomeColors.surface.withValues(alpha: 0.82),
            border: Border.all(
              color: _HomeColors.outline.withValues(alpha: 0.8),
            ),
          ),
          child: Icon(icon, color: _HomeColors.muted, size: 19),
        ),
      ),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '${_greetingFor(now)}.',
                style: const TextStyle(
                  color: _HomeColors.foreground,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _HomeColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _HomeColors.primary.withValues(alpha: 0.86),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'SYSTEM OPERATIONAL - ARCHIVE SYNCHRONIZED',
          style: TextStyle(
            color: _HomeColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DateStatusBanner extends StatelessWidget {
  const _DateStatusBanner({
    required this.now,
    required this.insight,
    required this.archiveTotal,
    required this.isLoading,
  });

  final DateTime now;
  final InsightData? insight;
  final int archiveTotal;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMM').format(now).toUpperCase();
    final day = now.day.toString().padLeft(2, '0');
    final completionRate = insight == null
        ? null
        : (insight!.completionRate * 100).clamp(0, 100).round();

    return _GlassPanel(
      padding: const EdgeInsets.all(24),
      borderColor: _HomeColors.primary.withValues(alpha: 0.28),
      child: Stack(
        children: [
          const Positioned(top: -18, right: -8, child: _GhostClockIcon()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$month $day',
                          style: const TextStyle(
                            color: _HomeColors.foreground,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: _HomeColors.tertiary,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                _statusText(
                                  isLoading: isLoading,
                                  archiveTotal: archiveTotal,
                                  completionRate: completionRate,
                                ),
                                style: const TextStyle(
                                  color: _HomeColors.tertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: _HomeColors.tertiary,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'LOCAL TIME',
                        style: TextStyle(
                          color: _HomeColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm:ss').format(now),
                        style: const TextStyle(
                          color: _HomeColors.secondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: _HomeColors.secondary, blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusText({
    required bool isLoading,
    required int archiveTotal,
    required int? completionRate,
  }) {
    if (isLoading) return 'INDEXING ARCHIVE DATA';
    if (archiveTotal == 0) return 'READY FOR FIRST CAPTURE';
    if (completionRate == null) return '$archiveTotal RECORDS INDEXED';
    return '$archiveTotal RECORDS - $completionRate% PRAYER RHYTHM';
  }
}

class _GhostClockIcon extends StatelessWidget {
  const _GhostClockIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.schedule_rounded,
      color: _HomeColors.foreground.withValues(alpha: 0.07),
      size: 124,
    );
  }
}

class _HomeBento extends StatelessWidget {
  const _HomeBento({
    required this.insight,
    required this.insightLoading,
    required this.notesCount,
    required this.indexesCount,
    required this.accountsCount,
  });

  final InsightData? insight;
  final bool insightLoading;
  final int? notesCount;
  final int? indexesCount;
  final int? accountsCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _InsightCard(insight: insight, isLoading: insightLoading),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionTile(
                            label: 'Checklist',
                            meta: indexesCount == null
                                ? 'Syncing'
                                : '${indexesCount.toString()} indexes',
                            icon: Icons.checklist_rounded,
                            accent: _HomeColors.tertiary,
                            onTap: () => _open(context, const AddIndexPage()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionTile(
                            label: 'Vault',
                            meta: accountsCount == null
                                ? 'Syncing'
                                : '${accountsCount.toString()} records',
                            icon: Icons.account_balance_wallet_rounded,
                            accent: _HomeColors.secondary,
                            onTap: () =>
                                _open(context, const AddCredentialPage()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _CaptureCard(notesCount: notesCount)),
            ],
          );
        }

        return Column(
          children: [
            _InsightCard(insight: insight, isLoading: insightLoading),
            const SizedBox(height: 12),
            _CaptureCard(notesCount: notesCount),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    label: 'Checklist',
                    meta: indexesCount == null
                        ? 'Syncing'
                        : '${indexesCount.toString()} indexes',
                    icon: Icons.checklist_rounded,
                    accent: _HomeColors.tertiary,
                    onTap: () => _open(context, const AddIndexPage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionTile(
                    label: 'Vault',
                    meta: accountsCount == null
                        ? 'Syncing'
                        : '${accountsCount.toString()} records',
                    icon: Icons.account_balance_wallet_rounded,
                    accent: _HomeColors.secondary,
                    onTap: () => _open(context, const AddCredentialPage()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.isLoading});

  final InsightData? insight;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final progress = insight == null
        ? 0.0
        : (insight!.completionRate).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return _GlassButton(
      onTap: () => _open(context, const InsightPage()),
      borderColor: _HomeColors.secondary.withValues(alpha: 0.16),
      child: SizedBox(
        height: 144,
        child: Stack(
          children: [
            Positioned(
              top: -48,
              right: -46,
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _HomeColors.secondary.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MEMORY INSIGHTS',
                            style: TextStyle(
                              color: _HomeColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Weekly synthesis',
                            style: TextStyle(
                              color: _HomeColors.foreground,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            isLoading
                                ? 'Reading archive signals'
                                : '${insight?.totalContent ?? 0} saved records across your archive.',
                            style: const TextStyle(
                              color: _HomeColors.muted,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.trending_up_rounded,
                      color: _HomeColors.secondary,
                      size: 23,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: isLoading ? null : progress,
                          backgroundColor: _HomeColors.surfaceHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _HomeColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isLoading ? 'SYNC' : '$percent%',
                      style: const TextStyle(
                        color: _HomeColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({required this.notesCount});

  final int? notesCount;

  @override
  Widget build(BuildContext context) {
    return _GlassButton(
      onTap: () => _open(context, const AddNotePage()),
      borderColor: _HomeColors.primary.withValues(alpha: 0.24),
      child: SizedBox(
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _HomeColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _HomeColors.primary.withValues(alpha: 0.34),
                ),
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: _HomeColors.primary,
                size: 31,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Capture new observation',
              style: TextStyle(
                color: _HomeColors.foreground,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const Spacer(),
            _CountBadge(
              label: notesCount == null
                  ? 'NOTES SYNCING'
                  : '${notesCount!.toString()} NOTES STORED',
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.meta,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String meta;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassButton(
      onTap: onTap,
      borderColor: accent.withValues(alpha: 0.16),
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 110,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 14),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomeColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTracker extends ConsumerWidget {
  const _ActivityTracker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityLast7DaysProvider);

    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      borderColor: _HomeColors.outline.withValues(alpha: 0.72),
      child: activityAsync.when(
        loading: _ActivityLoading.new,
        error: (error, stackTrace) => _ActivityError(
          onRetry: () => ref.invalidate(activityLast7DaysProvider),
        ),
        data: (days) => _ActivityChart(days: days),
      ),
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 210,
      child: Center(
        child: CircularProgressIndicator(
          color: _HomeColors.primary,
          strokeWidth: 2.2,
        ),
      ),
    );
  }
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
            color: _HomeColors.muted,
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            'Could not load activity',
            style: TextStyle(color: _HomeColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: _HomeColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.days});

  final List<ActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final total = days.fold<int>(0, (sum, day) => sum + day.total);
    final labels = days.map((day) => DateFormat('E').format(day.day)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'COGNITIVE ACTIVITY TRACKER',
                style: TextStyle(
                  color: _HomeColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Row(
              children: [
                _TinyDot(color: _HomeColors.primary),
                const SizedBox(width: 7),
                _TinyDot(color: _HomeColors.surfaceHighest),
                const SizedBox(width: 7),
                _TinyDot(color: _HomeColors.surfaceHighest),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$total entries this week',
          style: const TextStyle(
            color: _HomeColors.foreground,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 132,
          child: CustomPaint(
            painter: _ActivityChartPainter(days.map((d) => d.total).toList()),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (label) => Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: _HomeColors.muted.withValues(alpha: 0.56),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  const _ActivityChartPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxValue = math.max(1, values.reduce(math.max));
    final step = size.width / (values.length - 1);
    final points = List.generate(values.length, (index) {
      final ratio = values[index] / maxValue;
      final y = size.height * 0.1 + (1 - ratio) * size.height * 0.78;
      return Offset(index * step, y);
    });

    final curve = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      curve.cubicTo(
        midX,
        points[i].dy,
        midX,
        points[i + 1].dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }

    final fill = Path.from(curve)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _HomeColors.primary.withValues(alpha: 0.32),
            _HomeColors.primary.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      curve,
      Paint()
        ..color = _HomeColors.primary
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    final glow = Paint()
      ..color = _HomeColors.primary.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final dot = Paint()..color = _HomeColors.primary;
    final centerDot = Paint()..color = _HomeColors.surface;

    for (final point in points) {
      canvas.drawCircle(point, 6, glow);
      canvas.drawCircle(point, 3.4, dot);
      canvas.drawCircle(point, 1.4, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.insight});

  final InsightData? insight;

  @override
  Widget build(BuildContext context) {
    final streak = insight?.longestStreak ?? 0;
    final average = insight?.avgDailyPrayers ?? 0;

    return _GlassPanel(
      padding: EdgeInsets.zero,
      borderColor: _HomeColors.secondary.withValues(alpha: 0.16),
      child: InkWell(
        onTap: () => _open(context, const PrayerPage()),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 190,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _HomeColors.secondary.withValues(alpha: 0.08),
                _HomeColors.background.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _HomeColors.background.withValues(alpha: 0.64),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _HomeColors.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: _HomeColors.secondary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRAYER MEMORY',
                        style: TextStyle(
                          color: _HomeColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$streak-day streak - ${average.toStringAsFixed(1)} daily avg',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _HomeColors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.borderColor,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _HomeColors.surfaceHigh.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.child,
    required this.onTap,
    required this.borderColor,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback onTap;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: _GlassPanel(
          borderColor: borderColor,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _HomeColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _HomeColors.primary.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _HomeColors.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TinyDot extends StatelessWidget {
  const _TinyDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

void _open(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}
