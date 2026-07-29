class TagBreakdown {
  final String tag;
  final double amount;
  final int count;

  const TagBreakdown({
    required this.tag,
    required this.amount,
    required this.count,
  });
}

class MonthlyData {
  final int year;
  final int month;
  final double income;
  final double expense;

  const MonthlyData({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
  String get monthLabel {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

class FinancialInsightData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final int totalTransactions;
  final int incomeCount;
  final int expenseCount;
  final List<TagBreakdown> topExpenseTags;
  final List<TagBreakdown> topIncomeTags;
  final List<MonthlyData> monthlyTrend;

  const FinancialInsightData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalTransactions,
    required this.incomeCount,
    required this.expenseCount,
    required this.topExpenseTags,
    required this.topIncomeTags,
    required this.monthlyTrend,
  });
}
