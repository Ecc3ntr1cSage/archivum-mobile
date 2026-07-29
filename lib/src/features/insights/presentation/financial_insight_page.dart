import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/providers/financial_insight_provider.dart';
import '../domain/financial_insight_data.dart';

class FinancialInsightPage extends ConsumerWidget {
  const FinancialInsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clr = theme.colorScheme;
    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final primaryText = isDark ? Colors.white : Colors.black87;

    final dataAsync = ref.watch(financialInsightDataProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF10B981)),
            ),
          ),
        ),
        title: Text(
          'Financial Insights',
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
              onTap: () => ref.invalidate(financialInsightDataProvider),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.refresh, color: Color(0xFF10B981)),
              ),
            ),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: clr.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load financial data',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppError.from(error).message,
                  style: TextStyle(
                    color: primaryText.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(financialInsightDataProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _FinancialBody(data: data),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _FinancialBody extends StatelessWidget {
  final FinancialInsightData data;
  const _FinancialBody({required this.data});

  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1A2E) : Colors.white;
    final surfaceBg = isDark
        ? const Color(0xFF191121)
        : const Color(0xFFF7F6F8);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero balance card
            _buildBalanceHero(isDark, primaryText, secondaryText),
            const SizedBox(height: 16),
            // ── Income / Expense row
            _buildIncomeExpenseRow(isDark, primaryText, secondaryText, cardBg),
            const SizedBox(height: 20),
            // ── Monthly bar chart
            if (data.monthlyTrend.isNotEmpty) ...[
              _buildSectionLabel(
                Icons.bar_chart_rounded,
                'Monthly Trend',
                primaryText,
              ),
              const SizedBox(height: 12),
              _buildBarChart(
                isDark,
                primaryText,
                secondaryText,
                cardBg,
                surfaceBg,
              ),
              const SizedBox(height: 20),
            ],
            // ── Tag breakdowns
            _buildSectionLabel(
              Icons.sell_outlined,
              'Top Expense Categories',
              primaryText,
            ),
            const SizedBox(height: 12),
            _buildTagBreakdown(
              isDark,
              primaryText,
              secondaryText,
              cardBg,
              items: data.topExpenseTags,
              accent: _red,
              total: data.totalExpense,
              emptyLabel: 'No expenses recorded yet.',
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(
              Icons.trending_up_rounded,
              'Top Income Sources',
              primaryText,
            ),
            const SizedBox(height: 12),
            _buildTagBreakdown(
              isDark,
              primaryText,
              secondaryText,
              cardBg,
              items: data.topIncomeTags,
              accent: _green,
              total: data.totalIncome,
              emptyLabel: 'No income recorded yet.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Balance Hero ──────────────────────────────────────────────────────────

  Widget _buildBalanceHero(
    bool isDark,
    Color primaryText,
    Color secondaryText,
  ) {
    final isPositive = data.totalBalance >= 0;
    final balanceColor = isPositive ? _green : _red;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1D2D3A), const Color(0xFF15202B)]
              : [const Color(0xFF0F2027), const Color(0xFF2C5364)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'NET BALANCE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(data.totalBalance.abs()),
                style: TextStyle(
                  color: balanceColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: balanceColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPositive ? 'You\'re in the green' : 'Spending exceeds income',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroStat('TOTAL TXN', '${data.totalTransactions}', Colors.white),
              _heroStat('IN', '${data.incomeCount}', _green),
              _heroStat('OUT', '${data.expenseCount}', _red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Income / Expense Row ──────────────────────────────────────────────────

  Widget _buildIncomeExpenseRow(
    bool isDark,
    Color primaryText,
    Color secondaryText,
    Color cardBg,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            isDark: isDark,
            primaryText: primaryText,
            secondaryText: secondaryText,
            cardBg: cardBg,
            label: 'TOTAL INCOME',
            value: _formatCurrency(data.totalIncome),
            icon: Icons.trending_up_rounded,
            accent: _green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            isDark: isDark,
            primaryText: primaryText,
            secondaryText: secondaryText,
            cardBg: cardBg,
            label: 'TOTAL EXPENSE',
            value: _formatCurrency(data.totalExpense),
            icon: Icons.trending_down_rounded,
            accent: _red,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color cardBg,
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar Chart ─────────────────────────────────────────────────────────────

  Widget _buildBarChart(
    bool isDark,
    Color primaryText,
    Color secondaryText,
    Color cardBg,
    Color surfaceBg,
  ) {
    final months = data.monthlyTrend;
    // Show up to last 6 months
    final shown = months.length > 6
        ? months.sublist(months.length - 6)
        : months;
    final maxVal = shown.fold<double>(
      0,
      (prev, m) => max(prev, max(m.income, m.expense)),
    );
    const chartHeight = 100.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: shown.map((m) {
              final incomeH = maxVal > 0
                  ? (m.income / maxVal) * chartHeight
                  : 0.0;
              final expenseH = maxVal > 0
                  ? (m.expense / maxVal) * chartHeight
                  : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: chartHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Income bar
                                Container(
                                  width: 8,
                                  height: incomeH.clamp(2.0, chartHeight),
                                  decoration: BoxDecoration(
                                    color: _green,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                // Expense bar
                                Container(
                                  width: 8,
                                  height: expenseH.clamp(2.0, chartHeight),
                                  decoration: BoxDecoration(
                                    color: _red.withValues(alpha: 0.8),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.monthLabel,
                        style: TextStyle(
                          fontSize: 9,
                          color: secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(_green),
              const SizedBox(width: 4),
              Text(
                'Income',
                style: TextStyle(fontSize: 11, color: secondaryText),
              ),
              const SizedBox(width: 16),
              _legendDot(_red),
              const SizedBox(width: 4),
              Text(
                'Expense',
                style: TextStyle(fontSize: 11, color: secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
  );

  // ── Tag Breakdown ─────────────────────────────────────────────────────────

  Widget _buildTagBreakdown(
    bool isDark,
    Color primaryText,
    Color secondaryText,
    Color cardBg, {
    required List<TagBreakdown> items,
    required Color accent,
    required double total,
    required String emptyLabel,
  }) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          emptyLabel,
          style: TextStyle(color: secondaryText, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: items.map((item) {
          final pct = total > 0 ? item.amount / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.tag,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(item.amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, color: secondaryText),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: accent.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(IconData icon, String label, Color primaryText) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}
