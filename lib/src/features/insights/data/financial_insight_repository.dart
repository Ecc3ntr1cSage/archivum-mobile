import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/financial_insight_data.dart';

class FinancialInsightRepository {
  final SupabaseClient client;

  FinancialInsightRepository(this.client);

  Future<FinancialInsightData> fetchFinancialInsights() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Fetch all transactions for this user
    final rows = await client
        .from('transactions')
        .select('amount, status, tag, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    double totalIncome = 0;
    double totalExpense = 0;
    int incomeCount = 0;
    int expenseCount = 0;

    // Tag aggregation
    final Map<String, double> expenseByTag = {};
    final Map<String, int> expenseCountByTag = {};
    final Map<String, double> incomeByTag = {};
    final Map<String, int> incomeCountByTag = {};

    // Monthly aggregation: key = "yyyy-mm"
    final Map<String, ({double income, double expense})> monthly = {};

    for (final row in rows) {
      final amountCents = (row['amount'] as int?) ?? 0;
      final amount = amountCents / 100.0;
      final status = (row['status'] as int?) ?? 0;
      final tag = (row['tag'] as String?) ?? 'Other';
      final createdAtStr = row['created_at'] as String;
      final date = DateTime.parse(createdAtStr);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      final prev = monthly[monthKey] ?? (income: 0.0, expense: 0.0);

      if (status == 0) {
        // income
        totalIncome += amount;
        incomeCount++;
        incomeByTag[tag] = (incomeByTag[tag] ?? 0) + amount;
        incomeCountByTag[tag] = (incomeCountByTag[tag] ?? 0) + 1;
        monthly[monthKey] = (income: prev.income + amount, expense: prev.expense);
      } else {
        // expense
        totalExpense += amount;
        expenseCount++;
        expenseByTag[tag] = (expenseByTag[tag] ?? 0) + amount;
        expenseCountByTag[tag] = (expenseCountByTag[tag] ?? 0) + 1;
        monthly[monthKey] = (income: prev.income, expense: prev.expense + amount);
      }
    }

    // Build top expense tags (sorted by amount desc, top 5)
    final topExpenseTags = expenseByTag.entries
        .map((e) => TagBreakdown(
              tag: e.key,
              amount: e.value,
              count: expenseCountByTag[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Build top income tags (sorted by amount desc, top 5)
    final topIncomeTags = incomeByTag.entries
        .map((e) => TagBreakdown(
              tag: e.key,
              amount: e.value,
              count: incomeCountByTag[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Build monthly trend (sorted chronologically)
    final monthlyTrend = monthly.entries.map((e) {
      final parts = e.key.split('-');
      return MonthlyData(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        income: e.value.income,
        expense: e.value.expense,
      );
    }).toList()
      ..sort((a, b) {
        final cmpYear = a.year.compareTo(b.year);
        return cmpYear != 0 ? cmpYear : a.month.compareTo(b.month);
      });

    return FinancialInsightData(
      totalBalance: totalIncome - totalExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalTransactions: rows.length,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      topExpenseTags: topExpenseTags.take(5).toList(),
      topIncomeTags: topIncomeTags.take(5).toList(),
      monthlyTrend: monthlyTrend,
    );
  }
}
