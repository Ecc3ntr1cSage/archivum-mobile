import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';

import '../../finance/domain/transaction.dart';
import '../domain/financial_insight_data.dart';

class FinancialInsightRepository {
  final SupabaseClient client;

  FinancialInsightRepository(this.client);

  Future<FinancialInsightData> fetchFinancialInsights() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AppError.auth('You must be signed in to view insights.');
    }

    final rows = await client
        .from('transactions')
        .select('id, amount, status, date, created_at')
        .eq('user_id', userId)
        .eq('recurring', false)
        .neq('status', TransactionType.transfer.index)
        .order('created_at', ascending: true);

    final transactionRows = rows as List;
    final transactionById = {
      for (final row in transactionRows) row['id'].toString(): row,
    };
    final ids = transactionById.keys.toList();

    final splitRows = ids.isEmpty
        ? <dynamic>[]
        : await client
              .from('transaction_splits')
              .select('transaction_id, amount, tags(text)')
              .inFilter('transaction_id', ids);

    double totalIncome = 0;
    double totalExpense = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    final expenseByTag = <String, double>{};
    final expenseCountByTag = <String, int>{};
    final incomeByTag = <String, double>{};
    final incomeCountByTag = <String, int>{};
    final monthly = <String, ({double income, double expense})>{};

    for (final row in transactionRows) {
      final amount = ((row['amount'] as num?) ?? 0) / 100;
      final status = (row['status'] as int?) ?? 0;
      final dateSource = row['date'] ?? row['created_at'];
      final date = DateTime.parse(dateSource as String);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final prev = monthly[monthKey] ?? (income: 0.0, expense: 0.0);

      if (status == TransactionType.income.index) {
        totalIncome += amount;
        incomeCount++;
        monthly[monthKey] = (
          income: prev.income + amount,
          expense: prev.expense,
        );
      } else {
        totalExpense += amount;
        expenseCount++;
        monthly[monthKey] = (
          income: prev.income,
          expense: prev.expense + amount,
        );
      }
    }

    for (final row in splitRows) {
      final transaction = transactionById[row['transaction_id'].toString()];
      if (transaction == null) continue;
      final status = (transaction['status'] as int?) ?? 0;
      final amount = ((row['amount'] as num?) ?? 0) / 100;
      final tagRow = row['tags'];
      final tag = tagRow is Map<String, dynamic>
          ? tagRow['text']?.toString() ?? 'Other'
          : 'Other';

      if (status == TransactionType.income.index) {
        incomeByTag[tag] = (incomeByTag[tag] ?? 0) + amount;
        incomeCountByTag[tag] = (incomeCountByTag[tag] ?? 0) + 1;
      } else if (status == TransactionType.expense.index) {
        expenseByTag[tag] = (expenseByTag[tag] ?? 0) + amount;
        expenseCountByTag[tag] = (expenseCountByTag[tag] ?? 0) + 1;
      }
    }

    final topExpenseTags =
        expenseByTag.entries
            .map(
              (entry) => TagBreakdown(
                tag: entry.key,
                amount: entry.value,
                count: expenseCountByTag[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final topIncomeTags =
        incomeByTag.entries
            .map(
              (entry) => TagBreakdown(
                tag: entry.key,
                amount: entry.value,
                count: incomeCountByTag[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final monthlyTrend =
        monthly.entries.map((entry) {
          final parts = entry.key.split('-');
          return MonthlyData(
            year: int.parse(parts[0]),
            month: int.parse(parts[1]),
            income: entry.value.income,
            expense: entry.value.expense,
          );
        }).toList()..sort((a, b) {
          final cmpYear = a.year.compareTo(b.year);
          return cmpYear != 0 ? cmpYear : a.month.compareTo(b.month);
        });

    return FinancialInsightData(
      totalBalance: totalIncome - totalExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalTransactions: transactionRows.length,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      topExpenseTags: topExpenseTags.take(5).toList(),
      topIncomeTags: topIncomeTags.take(5).toList(),
      monthlyTrend: monthlyTrend,
    );
  }
}
