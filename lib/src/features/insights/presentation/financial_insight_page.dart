import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/providers/financial_insight_provider.dart';
import '../domain/financial_insight_data.dart';
import 'insight_design.dart';

class FinancialInsightPage extends ConsumerWidget {
  const FinancialInsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = InsightPalette.of(context);
    final insightAsync = ref.watch(financialInsightDataProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            children: [
              InsightTopBar(
                palette: palette,
                title: 'Financial insights',
                onBack: () => Navigator.pop(context),
                onRefresh: () => ref.invalidate(financialInsightDataProvider),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: insightAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: palette.sage,
                      strokeWidth: 2,
                    ),
                  ),
                  error: (error, stack) => _FinancialError(
                    palette: palette,
                    message: AppError.from(error).message,
                    onRetry: () => ref.invalidate(financialInsightDataProvider),
                  ),
                  data: (data) => _FinancialBody(data: data, palette: palette),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialError extends StatelessWidget {
  const _FinancialError({
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
            Icon(Icons.query_stats_rounded, color: palette.sage, size: 34),
            const SizedBox(height: 16),
            Text(
              'No numbers to show',
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
                foregroundColor: palette.sage,
                backgroundColor: palette.mint,
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

class _FinancialBody extends StatelessWidget {
  const _FinancialBody({required this.data, required this.palette});

  final FinancialInsightData data;
  final InsightPalette palette;

  static const _income = Color(0xFF5F9E88);
  static const _expense = Color(0xFFC87558);

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
          InsightReveal(index: 1, child: _buildBalanceHero()),
          const SizedBox(height: 18),
          InsightReveal(index: 2, child: _buildSummaryMetrics()),
          const SizedBox(height: 28),
          InsightReveal(index: 3, child: _buildTrendSection()),
          const SizedBox(height: 28),
          InsightReveal(index: 4, child: _buildExpenseSection()),
          const SizedBox(height: 28),
          InsightReveal(index: 5, child: _buildIncomeSection()),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightEyebrow(label: 'FINANCE / 02', palette: palette),
        const SizedBox(height: 14),
        Text(
          'Money, in\nproportion.',
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
          'A quiet read on the movement behind your everyday choices.',
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

  Widget _buildBalanceHero() {
    final positive = data.totalBalance >= 0;
    final accent = positive ? _income : _expense;
    return InsightSurface(
      palette: palette,
      padding: const EdgeInsets.all(5),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [
              palette.sage.withValues(alpha: palette.isDark ? 0.3 : 0.15),
              palette.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NET POSITION',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                InsightPill(
                  palette: palette,
                  label: positive ? 'IN BALANCE' : 'REVIEW',
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 17),
            Text(
              _formatCurrency(data.totalBalance),
              style: TextStyle(
                color: accent,
                fontSize: 40,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: palette.hairline),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data.totalTransactions} posted transactions',
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
                Icon(Icons.north_east_rounded, color: accent, size: 17),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final income = InsightMetricTile(
          palette: palette,
          label: 'INCOME',
          value: _formatCurrency(data.totalIncome),
          accent: _income,
          icon: Icons.arrow_downward_rounded,
        );
        final expense = InsightMetricTile(
          palette: palette,
          label: 'EXPENSE',
          value: _formatCurrency(data.totalExpense),
          accent: _expense,
          icon: Icons.arrow_upward_rounded,
        );
        return constraints.maxWidth < 360
            ? Column(children: [income, const SizedBox(height: 10), expense])
            : Row(
                children: [
                  Expanded(child: income),
                  const SizedBox(width: 10),
                  Expanded(child: expense),
                ],
              );
      },
    );
  }

  Widget _buildTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightSectionHeader(
          palette: palette,
          eyebrow: '01 / PULSE',
          title: 'Monthly movement',
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 12),
        InsightSurface(palette: palette, child: _buildChart()),
      ],
    );
  }

  Widget _buildChart() {
    final months = data.monthlyTrend.length > 6
        ? data.monthlyTrend.sublist(data.monthlyTrend.length - 6)
        : data.monthlyTrend;
    if (months.isEmpty) {
      return InsightEmptyState(
        palette: palette,
        label: 'Your first transaction will start the trend line.',
      );
    }
    final maxValue = months.fold<double>(
      0,
      (current, month) =>
          math.max(current, math.max(month.income, month.expense)),
    );
    return Column(
      children: [
        SizedBox(
          height: 156,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((month) {
              final incomeHeight = maxValue == 0
                  ? 3.0
                  : (month.income / maxValue * 118).clamp(3.0, 118.0);
              final expenseHeight = maxValue == 0
                  ? 3.0
                  : (month.expense / maxValue * 118).clamp(3.0, 118.0);
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 9,
                            height: incomeHeight,
                            decoration: BoxDecoration(
                              color: _income,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            width: 9,
                            height: expenseHeight,
                            decoration: BoxDecoration(
                              color: _expense.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      month.monthLabel,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(_income, 'Income'),
            const SizedBox(width: 18),
            _legend(_expense, 'Expense'),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: palette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseSection() {
    return _buildTagSection(
      eyebrow: '02 / OUTFLOW',
      title: 'Where it leaves',
      icon: Icons.arrow_upward_rounded,
      items: data.topExpenseTags,
      accent: _expense,
      total: data.totalExpense,
      emptyLabel: 'No expenses recorded in this period.',
    );
  }

  Widget _buildIncomeSection() {
    return _buildTagSection(
      eyebrow: '03 / INFLOW',
      title: 'Where it enters',
      icon: Icons.arrow_downward_rounded,
      items: data.topIncomeTags,
      accent: _income,
      total: data.totalIncome,
      emptyLabel: 'No income recorded in this period.',
    );
  }

  Widget _buildTagSection({
    required String eyebrow,
    required String title,
    required IconData icon,
    required List<TagBreakdown> items,
    required Color accent,
    required double total,
    required String emptyLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightSectionHeader(
          palette: palette,
          eyebrow: eyebrow,
          title: title,
          icon: icon,
        ),
        const SizedBox(height: 12),
        InsightSurface(
          palette: palette,
          child: items.isEmpty
              ? InsightEmptyState(palette: palette, label: emptyLabel)
              : Column(
                  children: items
                      .map((item) => _buildTagRow(item, accent, total))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTagRow(TagBreakdown item, Color accent, double total) {
    final ratio = total > 0 ? (item.amount / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.tag,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatCurrency(item.amount),
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 6, color: accent.withValues(alpha: 0.12)),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.count} transaction${item.count == 1 ? '' : 's'}',
            style: TextStyle(color: palette.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final absolute = amount.abs();
    final prefix = amount < 0 ? r'-$' : r'$';
    if (absolute >= 1000000) {
      return '$prefix${(absolute / 1000000).toStringAsFixed(2)}M';
    }
    if (absolute >= 1000) {
      return '$prefix${(absolute / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix${absolute.toStringAsFixed(2)}';
  }
}
