import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';

import '../domain/transaction.dart';

class TransactionRepository {
  final SupabaseClient client;
  TransactionRepository(this.client);

  int _toCents(double amount) => (amount * 100).round();

  Object? _dbId(String? value) =>
      value == null ? null : int.tryParse(value) ?? value;

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _transferToken(String userId) {
    return '$userId-${DateTime.now().microsecondsSinceEpoch}';
  }

  TransactionType _parseTransactionType(Object? rawStatus) {
    final status = (rawStatus as num?)?.toInt();
    if (status == null ||
        status < 0 ||
        status >= TransactionType.values.length) {
      throw AppError.database('A transaction has an invalid status.');
    }
    return TransactionType.values[status];
  }

  Future<String> _requireUserId() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw AppError.auth('You must be signed in to manage transactions.');
    }
    return userId;
  }

  Future<void> _logActivity(String activityType) async {
    await client.from('activity_logs').insert({'activity_type': activityType});
  }

  Future<FinancialAccount> createAccount(FinancialAccount account) async {
    final userId = await _requireUserId();
    final payload = account.toJson()..['user_id'] = userId;
    final response = await client
        .from('accounts')
        .insert(payload)
        .select()
        .single();
    await _logActivity('finance_account_created');
    return FinancialAccount.fromJson(response);
  }

  Future<List<FinancialAccount>> getAccounts() async {
    final userId = await _requireUserId();
    final accountRows = await client
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final accounts = (accountRows as List)
        .map((row) => FinancialAccount.fromJson(row))
        .toList();
    if (accounts.isEmpty) return accounts;

    final txRows = await client
        .from('transactions')
        .select('account_id, status, amount, recurring, transfer_side')
        .eq('user_id', userId)
        .eq('recurring', false);

    final deltas = <String, double>{};
    for (final row in txRows as List) {
      final accountId = row['account_id']?.toString();
      if (accountId == null) continue;
      final type = _parseTransactionType(row['status']);
      final amount = ((row['amount'] as num?) ?? 0) / 100;
      var delta = 0.0;

      if (type == TransactionType.income) {
        delta = amount;
      } else if (type == TransactionType.expense) {
        delta = -amount;
      } else if (row['transfer_side'] == 'in') {
        delta = amount;
      } else {
        delta = -amount;
      }

      deltas[accountId] = (deltas[accountId] ?? 0) + delta;
    }

    return accounts
        .map(
          (account) => account.copyWith(
            currentBalance: account.openingBalance + (deltas[account.id] ?? 0),
          ),
        )
        .toList();
  }

  Future<void> createTransaction(TransactionModel transaction) async {
    final userId = await _requireUserId();
    if (!transaction.amount.isFinite || transaction.amount <= 0) {
      throw AppError.validation(
        'Transaction amount must be greater than zero.',
      );
    }
    if (transaction.accountId == null) {
      throw AppError.validation('Please select an account.');
    }
    if (transaction.type != TransactionType.transfer &&
        transaction.splits.isEmpty) {
      throw AppError.validation('Please add at least one tag split.');
    }
    if (transaction.recurring && transaction.type != TransactionType.expense) {
      throw AppError.validation('Only expenses can be saved as recurring.');
    }

    final splitTotal = transaction.splits.fold<double>(
      0,
      (sum, split) => sum + split.amount,
    );
    if (transaction.type != TransactionType.transfer &&
        _toCents(splitTotal) != _toCents(transaction.amount)) {
      throw AppError.validation(
        'Split amounts must equal the transaction amount.',
      );
    }

    final inserted = await client
        .from('transactions')
        .insert({
          'user_id': userId,
          'account_id': _dbId(transaction.accountId),
          'status': transaction.type.index,
          'amount': _toCents(transaction.amount),
          'merchant': transaction.merchant,
          'details': transaction.details,
          'date': _formatDate(transaction.date),
          'recurring': transaction.recurring,
          'recurring_source_id': _dbId(transaction.recurringSourceId),
          'transfer_id': transaction.transferId,
          'transfer_side': transaction.transferSide == null
              ? null
              : transaction.transferSide == TransferSide.in_
              ? 'in'
              : 'out',
          'created_at': transaction.createdAt.toIso8601String(),
        })
        .select('id')
        .single();

    final transactionId = inserted['id'].toString();
    if (transaction.type != TransactionType.transfer) {
      await client
          .from('transaction_splits')
          .insert(
            transaction.splits
                .map(
                  (split) => {
                    'transaction_id': transactionId,
                    'tag_id': _dbId(split.tagId),
                    'amount': _toCents(split.amount),
                  },
                )
                .toList(),
          );
    }

    final activityType = transaction.recurring
        ? 'recurring_expense_created'
        : transaction.type == TransactionType.income
        ? 'income_created'
        : transaction.type == TransactionType.expense
        ? 'expense_created'
        : 'transfer_created';
    await _logActivity(activityType);
  }

  Future<void> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String details,
    DateTime? date,
  }) async {
    final userId = await _requireUserId();
    if (fromAccountId == toAccountId) {
      throw AppError.validation('Choose two different accounts.');
    }
    if (!amount.isFinite || amount <= 0) {
      throw AppError.validation('Transfer amount must be greater than zero.');
    }

    final accounts = await getAccounts();
    final from = accounts
        .where((account) => account.id == fromAccountId)
        .firstOrNull;
    final to = accounts
        .where((account) => account.id == toAccountId)
        .firstOrNull;
    if (from == null || to == null) {
      throw AppError.validation('Choose two valid accounts.');
    }
    if (from.currency != to.currency) {
      throw AppError.validation(
        'Transfers only support same-currency accounts.',
      );
    }

    final transferId = _transferToken(userId);
    final now = DateTime.now();
    final payload = [
      {
        'user_id': userId,
        'account_id': _dbId(fromAccountId),
        'status': TransactionType.transfer.index,
        'amount': _toCents(amount),
        'details': details,
        'date': _formatDate(date),
        'recurring': false,
        'transfer_id': transferId,
        'transfer_side': 'out',
        'created_at': now.toIso8601String(),
      },
      {
        'user_id': userId,
        'account_id': _dbId(toAccountId),
        'status': TransactionType.transfer.index,
        'amount': _toCents(amount),
        'details': details,
        'date': _formatDate(date),
        'recurring': false,
        'transfer_id': transferId,
        'transfer_side': 'in',
        'created_at': now.toIso8601String(),
      },
    ];

    await client.from('transactions').insert(payload);
    await _logActivity('transfer_created');
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final userId = await _requireUserId();
    if (transaction.id.isEmpty || transaction.accountId == null) {
      throw AppError.validation('A transaction and account are required.');
    }
    if (!transaction.amount.isFinite || transaction.amount <= 0) {
      throw AppError.validation(
        'Transaction amount must be greater than zero.',
      );
    }
    if (transaction.type == TransactionType.transfer) {
      throw AppError.validation(
        'Edit transfers by deleting and recreating them.',
      );
    }
    final splitTotal = transaction.splits.fold<double>(
      0,
      (sum, split) => sum + split.amount,
    );
    if (_toCents(splitTotal) != _toCents(transaction.amount)) {
      throw AppError.validation(
        'Split amounts must equal the transaction amount.',
      );
    }

    await client
        .from('transactions')
        .update({
          'account_id': _dbId(transaction.accountId),
          'status': transaction.type.index,
          'amount': _toCents(transaction.amount),
          'merchant': transaction.merchant,
          'details': transaction.details,
          'date': _formatDate(transaction.date),
          'recurring': transaction.recurring,
        })
        .eq('id', transaction.id)
        .eq('user_id', userId);

    await client
        .from('transaction_splits')
        .delete()
        .eq('transaction_id', transaction.id);
    await client
        .from('transaction_splits')
        .insert(
          transaction.splits
              .map(
                (split) => {
                  'transaction_id': transaction.id,
                  'tag_id': _dbId(split.tagId),
                  'amount': _toCents(split.amount),
                },
              )
              .toList(),
        );

    await _logActivity(
      transaction.type == TransactionType.income
          ? 'income_updated'
          : 'expense_updated',
    );
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final userId = await _requireUserId();
    if (transaction.type == TransactionType.transfer &&
        transaction.transferId != null) {
      await client
          .from('transactions')
          .delete()
          .eq('transfer_id', transaction.transferId!)
          .eq('user_id', userId);
    } else {
      await client
          .from('transactions')
          .delete()
          .eq('id', transaction.id)
          .eq('user_id', userId);
    }
    await _logActivity(
      transaction.type == TransactionType.income
          ? 'income_deleted'
          : transaction.type == TransactionType.expense
          ? 'expense_deleted'
          : 'transfer_deleted',
    );
  }

  Future<void> cloneRecurringTransaction(TransactionModel template) async {
    await createTransaction(
      TransactionModel(
        id: '',
        accountId: template.accountId,
        type: template.type,
        amount: template.amount,
        merchant: template.merchant,
        details: template.details,
        date: DateTime.now(),
        recurring: false,
        recurringSourceId: template.id,
        splits: template.splits,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<FinanceTag> addTag(String text, String feature) async {
    final userId = await _requireUserId();
    final response = await client
        .from('tags')
        .insert({'text': text, 'feature': feature, 'user_id': userId})
        .select('id, text')
        .single();
    return FinanceTag.fromJson(response);
  }

  Future<List<FinanceTag>> getTags(String feature) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('tags')
        .select('id, text')
        .eq('feature', feature)
        .eq('user_id', userId)
        .order('text');

    return (response as List).map((row) => FinanceTag.fromJson(row)).toList();
  }

  Future<List<TransactionModel>> getTransactions({
    bool includeRecurring = false,
    bool recurringOnly = false,
  }) async {
    final userId = await _requireUserId();

    var query = client
        .from('transactions')
        .select(
          '*, accounts(name, currency), transaction_splits(*, tags(text))',
        )
        .eq('user_id', userId);

    if (recurringOnly) {
      query = query
          .eq('recurring', true)
          .eq('status', TransactionType.expense.index);
    } else if (!includeRecurring) {
      query = query.eq('recurring', false);
    }

    final response = await query.order('created_at', ascending: false);
    final transactions = (response as List).map((row) {
      final date = row['date'] as String?;
      final account = row['accounts'];
      final splits = ((row['transaction_splits'] as List?) ?? [])
          .map((split) => TransactionSplit.fromJson(split))
          .toList();
      final transferSide = row['transfer_side'] == null
          ? null
          : row['transfer_side'] == 'in'
          ? TransferSide.in_
          : TransferSide.out;

      return TransactionModel(
        id: row['id']?.toString() ?? '',
        accountId: row['account_id']?.toString(),
        accountName: account is Map<String, dynamic>
            ? account['name']?.toString()
            : null,
        accountCurrency: account is Map<String, dynamic>
            ? account['currency']?.toString()
            : null,
        type: _parseTransactionType(row['status']),
        amount: ((row['amount'] as num?) ?? 0) / 100,
        merchant: row['merchant'] as String?,
        details: row['details'] as String? ?? '',
        date: date == null ? null : DateTime.parse(date),
        recurring: row['recurring'] as bool? ?? false,
        recurringSourceId: row['recurring_source_id']?.toString(),
        transferId: row['transfer_id']?.toString(),
        transferSide: transferSide,
        splits: splits,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();

    transactions.sort((a, b) {
      final byDisplayDate = b.displayDate.compareTo(a.displayDate);
      if (byDisplayDate != 0) return byDisplayDate;
      return b.createdAt.compareTo(a.createdAt);
    });

    return transactions;
  }

  Future<Budget> createBudget(Budget budget) async {
    final userId = await _requireUserId();
    final response = await client
        .from('budgets')
        .insert({
          'user_id': userId,
          'tag_id': _dbId(budget.tagId),
          'currency': budget.currency,
          'limit_amount': _toCents(budget.limitAmount),
          'period': budget.period,
          'start_date': _formatDate(budget.startDate),
          'end_date': _formatDate(budget.endDate),
          'is_active': budget.isActive,
        })
        .select('*, tags(text)')
        .single();
    await _logActivity('budget_created');
    return Budget.fromJson(response);
  }

  Future<List<Budget>> getBudgets() async {
    final userId = await _requireUserId();
    final rows = await client
        .from('budgets')
        .select('*, tags(text)')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final budgets = (rows as List).map((row) => Budget.fromJson(row)).toList();
    final transactions = await getTransactions();

    return budgets.map((budget) {
      final used = transactions
          .where(
            (transaction) =>
                transaction.type == TransactionType.expense &&
                !transaction.recurring &&
                !transaction.displayDate.isBefore(budget.startDate) &&
                !transaction.displayDate.isAfter(budget.endDate),
          )
          .expand((transaction) => transaction.splits)
          .where((split) => split.tagId == budget.tagId)
          .fold<double>(0, (sum, split) => sum + split.amount);
      return Budget(
        id: budget.id,
        tagId: budget.tagId,
        tagText: budget.tagText,
        currency: budget.currency,
        limitAmount: budget.limitAmount,
        period: budget.period,
        startDate: budget.startDate,
        endDate: budget.endDate,
        isActive: budget.isActive,
        usedAmount: used,
      );
    }).toList();
  }
}
