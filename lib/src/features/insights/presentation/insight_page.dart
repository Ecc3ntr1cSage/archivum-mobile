import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/insight_provider.dart';
import '../domain/insight_data.dart';
import 'financial_insight_page.dart';

class InsightPage extends ConsumerWidget {
  const InsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clr = theme.colorScheme;

    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final primaryText = isDark ? Colors.white : Colors.black87;

    final insightAsync = ref.watch(insightDataProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: clr.primary.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.arrow_back, color: clr.primary),
            ),
          ),
        ),
        title: Text(
          'Analytics',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => ref.invalidate(insightDataProvider),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: clr.primary.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.refresh, color: clr.primary),
              ),
            ),
          ),
        ],
      ),
      body: insightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: clr.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load insights',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: primaryText.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(insightDataProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _InsightBody(data: data),
      ),
    );
  }
}

class _InsightBody extends StatelessWidget {
  final InsightData data;
  const _InsightBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clr = theme.colorScheme;

    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final cardColor = isDark
        ? clr.primary.withValues(alpha: 0.05)
        : Colors.grey[100];
    final borderColor = clr.primary.withValues(alpha: 0.1);
    final primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNotesSection(
              context,
              clr,
              isDark,
              primaryText,
              secondaryText,
              cardColor,
              borderColor,
              bgColor,
            ),
            const SizedBox(height: 24),
            _buildIndexRegistrySection(
              clr,
              primaryText,
              secondaryText,
              cardColor,
              borderColor,
            ),
            const SizedBox(height: 24),
            _buildFaithStatisticsSection(
              clr,
              isDark,
              primaryText,
              secondaryText,
            ),
            const SizedBox(height: 24),
            _buildAccountSecuritySection(
              context,
              clr,
              isDark,
              primaryText,
              secondaryText,
              cardColor,
              borderColor,
            ),
            const SizedBox(height: 24),
            _buildFinancialRedirectCard(context, isDark, primaryText),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────
  Widget _buildSectionHeader(
    IconData icon,
    String title,
    Color iconColor,
    Color textColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ─── Notes ────────────────────────────────────────────────────
  Widget _buildNotesSection(
    BuildContext context,
    ColorScheme clr,
    bool isDark,
    Color primaryText,
    Color secondaryText,
    Color? cardColor,
    Color borderColor,
    Color bgColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          Icons.auto_stories,
          'Notes',
          clr.primary,
          primaryText,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL NOTES',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.totalNotes}',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: clr.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics, color: clr.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Sub Items
              _buildNotesSubItem(
                context: context,
                title: 'Tag Breakdown',
                count: '${data.totalNotes}',
                color: clr.primary,
                primaryText: primaryText,
                isDark: isDark,
                breakdownItems: data.noteTags,
                breakdownTitle: 'Notes Tags Breakdown',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSubItem({
    required BuildContext context,
    required String title,
    required String count,
    required Color color,
    required Color primaryText,
    required bool isDark,
    required List<TagBreakdown> breakdownItems,
    required String breakdownTitle,
  }) {
    final bgColor = isDark ? const Color(0xFF191121) : Colors.white;
    return InkWell(
      onTap: () =>
          _showBreakdownSheet(context, breakdownTitle, breakdownItems, color),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryText,
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'TAGS BREAKDOWN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Index Registry ───────────────────────────────────────────
  Widget _buildIndexRegistrySection(
    ColorScheme clr,
    Color primaryText,
    Color secondaryText,
    Color? cardColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          Icons.inventory_2,
          'Index Registry',
          clr.secondary,
          primaryText,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL INDEXES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.totalIndexes}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INDEX ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.totalIndexItems}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Faith Statistics ─────────────────────────────────────────
  Widget _buildFaithStatisticsSection(
    ColorScheme clr,
    bool isDark,
    Color primaryText,
    Color secondaryText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          Icons.volunteer_activism,
          'Faith Statistics',
          clr.primary,
          primaryText,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                clr.primary.withValues(alpha: 0.2),
                clr.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: clr.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFaithStatItem(
                'TOTAL PRAYERS',
                _formatNumber(data.totalPrayers),
                clr.primary,
                secondaryText,
              ),
              Container(
                width: 1,
                height: 40,
                color: clr.primary.withValues(alpha: 0.1),
              ),
              _buildFaithStatItem(
                'AVG DAILY',
                '${data.avgDailyPrayers}',
                clr.primary,
                secondaryText,
              ),
              Container(
                width: 1,
                height: 40,
                color: clr.primary.withValues(alpha: 0.1),
              ),
              Column(
                children: [
                  Text(
                    'STREAK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: secondaryText,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${data.longestStreak}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: clr.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.local_fire_department,
                        color: clr.secondary,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaithStatItem(
    String label,
    String value,
    Color valueColor,
    Color secondaryText,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─── Account Security ─────────────────────────────────────────
  Widget _buildAccountSecuritySection(
    BuildContext context,
    ColorScheme clr,
    bool isDark,
    Color primaryText,
    Color secondaryText,
    Color? cardColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          Icons.shield_outlined,
          'Account Security',
          clr.primary,
          primaryText,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL ACCOUNTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: secondaryText,
                          ),
                        ),
                        Text(
                          '${data.totalAccounts}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clr.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _showAccountBreakdownSheet(context, clr),
                      child: const Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'METHOD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: clr.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...data.accountMethods.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildAccountRow(
                                m.tag,
                                '${m.count}',
                                primaryText,
                              ),
                            ),
                          ),
                          if (data.accountMethods.isEmpty)
                            Text(
                              '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SSO PROVIDER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: clr.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...data.ssoProviders.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildAccountRow(
                                p.tag,
                                '${p.count}',
                                primaryText,
                              ),
                            ),
                          ),
                          if (data.ssoProviders.isEmpty)
                            Text(
                              '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryText,
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildAccountRow(String label, String value, Color primaryText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: primaryText)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
      ],
    );
  }

  // ─── Financial Redirect Card ──────────────────────────────────
  Widget _buildFinancialRedirectCard(
    BuildContext context,
    bool isDark,
    Color primaryText,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FinancialInsightPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF065F46)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF6EE7B7),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINANCIAL INSIGHTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6EE7B7),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Balance, income, expenses & trends',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF6EE7B7),
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Sheet Utilities ───────────────────────────────────

  void _showBreakdownSheet(
    BuildContext context,
    String title,
    List<TagBreakdown> items,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1529) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No data yet.',
                  style: TextStyle(color: secondaryText, fontSize: 14),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.tag,
                            style: TextStyle(fontSize: 14, color: primaryText),
                          ),
                        ],
                      ),
                      Text(
                        '${item.count}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAccountBreakdownSheet(BuildContext context, ColorScheme clr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1529) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Account Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${data.totalAccounts}',
              style: TextStyle(fontSize: 14, color: secondaryText),
            ),
            const SizedBox(height: 16),
            Text(
              'BY METHOD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: clr.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...data.accountMethods.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: clr.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          m.tag,
                          style: TextStyle(fontSize: 14, color: primaryText),
                        ),
                      ],
                    ),
                    Text(
                      '${m.count}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: clr.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (data.ssoProviders.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'SSO BREAKDOWN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: clr.secondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              ...data.ssoProviders.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: clr.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            p.tag,
                            style: TextStyle(fontSize: 14, color: primaryText),
                          ),
                        ],
                      ),
                      Text(
                        '${p.count}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: clr.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return '$number';
  }
}
