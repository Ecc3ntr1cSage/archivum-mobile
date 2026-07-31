import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/insight_provider.dart';
import '../domain/insight_data.dart';
import 'financial_insight_page.dart';
import 'insight_design.dart';

class InsightPage extends ConsumerWidget {
  const InsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = InsightPalette.of(context);
    final insightAsync = ref.watch(insightDataProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            children: [
              InsightTopBar(
                palette: palette,
                title: 'Analytics',
                onBack: () => Navigator.pop(context),
                onRefresh: () => ref.invalidate(insightDataProvider),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: insightAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: palette.ember,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (error, stack) => _InsightError(
                    palette: palette,
                    message: AppError.from(error).message,
                    onRetry: () => ref.invalidate(insightDataProvider),
                  ),
                  data: (data) => _InsightBody(data: data, palette: palette),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightError extends StatelessWidget {
  const _InsightError({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  final InsightPalette palette;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InsightSurface(
        palette: palette,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.ember, size: 34),
            const SizedBox(height: 16),
            Text(
              'The archive is quiet',
              style: TextStyle(
                color: palette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                foregroundColor: palette.ember,
                backgroundColor: palette.blush,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightBody extends StatelessWidget {
  const _InsightBody({required this.data, required this.palette});

  final InsightData data;
  final InsightPalette palette;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InsightReveal(index: 0, child: _buildIntro()),
          const SizedBox(height: 26),
          InsightReveal(index: 1, child: _buildArchiveOverview()),
          const SizedBox(height: 28),
          InsightReveal(index: 2, child: _buildNotesSection()),
          const SizedBox(height: 28),
          InsightReveal(index: 3, child: _buildIndexesSection()),
          const SizedBox(height: 28),
          InsightReveal(index: 4, child: _buildFaithSection()),
          const SizedBox(height: 28),
          InsightReveal(index: 5, child: _buildAccountsSection(context)),
          const SizedBox(height: 28),
          InsightReveal(index: 6, child: _buildFinanceLink(context)),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightEyebrow(label: 'PRIVATE ARCHIVE / 01', palette: palette),
        const SizedBox(height: 14),
        Text(
          'Your archive,\nin signal.',
          style: TextStyle(
            color: palette.ink,
            fontSize: 38,
            height: 0.98,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A considered view of the things you have chosen to keep close.',
          style: TextStyle(
            color: palette.muted,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildArchiveOverview() {
    return InsightSurface(
      palette: palette,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAVED RECORDS',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${data.totalContent}',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 38,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Across your personal archive',
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          InsightPill(
            palette: palette,
            label: 'LIVE VIEW',
            color: palette.sage,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightSectionHeader(
          palette: palette,
          eyebrow: '01 / MEMORY',
          title: 'Notes',
          icon: Icons.auto_stories_outlined,
        ),
        const SizedBox(height: 12),
        InsightSurface(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.totalNotes}',
                    style: TextStyle(
                      color: palette.ember,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'notes captured',
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'TAG CONSTELLATION',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _buildNoteTags(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteTags() {
    if (data.noteTags.isEmpty) {
      return InsightEmptyState(
        palette: palette,
        label: 'No note tags yet. Your first thread is waiting.',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: data.noteTags
          .take(8)
          .map(
            (item) => InsightPill(
              palette: palette,
              label: '${item.tag}  ${item.count}',
              color: palette.ember,
            ),
          )
          .toList(),
    );
  }

  Widget _buildIndexesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightSectionHeader(
          palette: palette,
          eyebrow: '02 / REGISTRY',
          title: 'Index registry',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 12),
        InsightSurface(
          palette: palette,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final children = [
                InsightMetricTile(
                  palette: palette,
                  label: 'INDEXES',
                  value: '${data.totalIndexes}',
                  accent: palette.sage,
                  icon: Icons.layers_outlined,
                ),
                InsightMetricTile(
                  palette: palette,
                  label: 'ITEMS',
                  value: '${data.totalIndexItems}',
                  accent: palette.ember,
                  icon: Icons.format_list_bulleted_rounded,
                ),
              ];
              return compact
                  ? Column(
                      children: [
                        children[0],
                        const SizedBox(height: 10),
                        children[1],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 10),
                        Expanded(child: children[1]),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFaithSection() {
    final progress = (data.completionRate / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightSectionHeader(
          palette: palette,
          eyebrow: '03 / RHYTHM',
          title: 'Prayer practice',
          icon: Icons.wb_sunny_outlined,
        ),
        const SizedBox(height: 12),
        InsightSurface(
          palette: palette,
          child: Row(
            children: [
              SizedBox(
                width: 102,
                height: 102,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: palette.sage.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(palette.sage),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'complete',
                          style: TextStyle(color: palette.muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.totalPrayers}',
                      style: TextStyle(
                        color: palette.sage,
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'prayers completed across ${data.totalPrayerDays} days',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 13),
                    InsightPill(
                      palette: palette,
                      label: '${data.avgDailyPrayers.toStringAsFixed(1)} / DAY',
                      color: palette.sage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightSectionHeader(
          palette: palette,
          eyebrow: '04 / ACCESS',
          title: 'Account security',
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 12),
        InsightSurface(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${data.totalAccounts} credentials stored',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    color: palette.ember,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'BY METHOD',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (data.accountMethods.isEmpty)
                InsightEmptyState(
                  palette: palette,
                  label: 'No credential methods recorded yet.',
                )
              else
                ...data.accountMethods.map(
                  (item) => InsightListRow(
                    palette: palette,
                    label: item.tag,
                    value: '${item.count}',
                    accent: palette.ember,
                  ),
                ),
              if (data.ssoProviders.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'SSO PROVIDERS',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.ssoProviders.map(
                  (item) => InsightListRow(
                    palette: palette,
                    label: item.tag,
                    value: '${item.count}',
                    accent: palette.sage,
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showAccountBreakdown(context),
                  icon: const Icon(Icons.arrow_outward_rounded, size: 15),
                  label: const Text('View details'),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.ember,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceLink(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinancialInsightPage()),
        ),
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [palette.ember, palette.ember.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.ember.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FINANCIAL LENS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'See where your money is moving.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountBreakdown(BuildContext context) {
    _showBreakdownSheet(
      context,
      title: 'Account breakdown',
      subtitle: '${data.totalAccounts} credentials in your archive',
      children: [
        Text(
          'BY METHOD',
          style: TextStyle(
            color: palette.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        ...data.accountMethods.map(
          (item) => InsightListRow(
            palette: palette,
            label: item.tag,
            value: '${item.count}',
            accent: palette.ember,
          ),
        ),
        if (data.ssoProviders.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'SSO PROVIDERS',
            style: TextStyle(
              color: palette.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...data.ssoProviders.map(
            (item) => InsightListRow(
              palette: palette,
              label: item.tag,
              value: '${item.count}',
              accent: palette.sage,
            ),
          ),
        ],
      ],
    );
  }

  void _showBreakdownSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.hairline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
