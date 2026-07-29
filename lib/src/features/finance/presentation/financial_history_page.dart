import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

class FinancialHistoryPage extends StatefulWidget {
  const FinancialHistoryPage({super.key});

  @override
  State<FinancialHistoryPage> createState() => _FinancialHistoryPageState();
}

class _FinancialHistoryPageState extends State<FinancialHistoryPage> {
  final _repository = TransactionRepository(Supabase.instance.client);
  final _search = TextEditingController();

  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  bool _isLoading = true;
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _repository.getTransactions();
      if (!mounted) return;
      setState(() {
        _all = transactions;
        _filtered = transactions;
        _isLoading = false;
      });
      _applyFilters();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load transactions: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    }
  }

  void _applyFilters() {
    final query = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((transaction) {
        final matchesType =
            _selectedType == 'All' ||
            (_selectedType == 'Income' &&
                transaction.type == TransactionType.income) ||
            (_selectedType == 'Expense' &&
                transaction.type == TransactionType.expense) ||
            (_selectedType == 'Transfer' &&
                transaction.type == TransactionType.transfer);
        final haystack = [
          transaction.details,
          transaction.merchant ?? '',
          transaction.accountName ?? '',
          transaction.tagLabel,
        ].join(' ').toLowerCase();
        return matchesType && (query.isEmpty || haystack.contains(query));
      }).toList();
    });
  }

  double get _incomeTotal => _filtered
      .where((transaction) => transaction.type == TransactionType.income)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get _expenseTotal => _filtered
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  Future<void> _delete(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction'),
        content: Text(
          transaction.type == TransactionType.transfer
              ? 'This will delete both sides of the transfer.'
              : 'This will delete this transaction and its split rows.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _repository.deleteTransaction(transaction);
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final background = isDark ? Colors.black : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Financial History'),
        backgroundColor: surface,
        actions: [
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Income',
                              amount: _incomeTotal,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Expense',
                              amount: _expenseTotal,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (_) => _applyFilters(),
                        decoration: const InputDecoration(
                          hintText: 'Search transactions, accounts, tags',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(
                            value: 'Income',
                            child: Text('Income'),
                          ),
                          DropdownMenuItem(
                            value: 'Expense',
                            child: Text('Expense'),
                          ),
                          DropdownMenuItem(
                            value: 'Transfer',
                            child: Text('Transfer'),
                          ),
                        ],
                        onChanged: (value) {
                          _selectedType = value ?? 'All';
                          _applyFilters();
                        },
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No transactions found'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final transaction = _filtered[index];
                            return _TransactionTile(
                              transaction: transaction,
                              onDelete: () => _delete(transaction),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 6),
            Text(
              amount.toStringAsFixed(2),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.onDelete});

  final TransactionModel transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final color = isTransfer
        ? const Color(0xFF5277C3)
        : isIncome
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final prefix = isTransfer
        ? transaction.transferSide == TransferSide.in_
              ? '+'
              : '-'
        : isIncome
        ? '+'
        : '-';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          isTransfer
              ? Icons.swap_horiz
              : isIncome
              ? Icons.south_west
              : Icons.north_east,
          color: color,
        ),
      ),
      title: Text(
        transaction.merchant?.isNotEmpty == true
            ? transaction.merchant!
            : transaction.details.isNotEmpty
            ? transaction.details
            : isTransfer
            ? 'Transfer'
            : 'Transaction',
      ),
      subtitle: Text(
        [
          DateFormat('MMM d, yyyy').format(transaction.displayDate),
          if ((transaction.accountName ?? '').isNotEmpty)
            transaction.accountName!,
          transaction.tagLabel,
        ].join(' • '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$prefix${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
