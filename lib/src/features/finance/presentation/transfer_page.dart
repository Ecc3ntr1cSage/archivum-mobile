import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  static const _accent = Color(0xFF5277C3);

  late final TransactionRepository _repo;
  final _amount = TextEditingController();
  final _details = TextEditingController();
  List<FinancialAccount> _accounts = [];
  FinancialAccount? _from;
  FinancialAccount? _to;
  DateTime? _date;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = TransactionRepository(Supabase.instance.client);
    Future.microtask(_loadAccounts);
  }

  @override
  void dispose() {
    _amount.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _repo.getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _from = accounts.isEmpty ? null : accounts.first;
        _to = accounts.length > 1 ? accounts[1] : null;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(AppError.from(error, stackTrace).message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }
    if (_from == null || _to == null) {
      _showError('Choose both accounts');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _repo.createTransfer(
        fromAccountId: _from!.id!,
        toAccountId: _to!.id!,
        amount: amount,
        details: _details.text.trim(),
        date: _date,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      if (mounted) _showError(AppError.from(error, stackTrace).message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Transfer'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.length < 2
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Create at least two finance accounts before transferring.',
                  style: TextStyle(color: theme.mutedForeground),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                Text(
                  'All accounts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose where money moves from and where it lands.',
                  style: TextStyle(color: theme.mutedForeground),
                ),
                const SizedBox(height: 16),
                _AccountSelector(
                  label: 'From',
                  selected: _from,
                  accounts: _accounts
                      .where((account) => account.id != _to?.id)
                      .toList(),
                  accent: _accent,
                  onChanged: (account) => setState(() => _from = account),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(
                    Icons.south_rounded,
                    color: theme.mutedForeground,
                  ),
                ),
                _AccountSelector(
                  label: 'To',
                  selected: _to,
                  accounts: _accounts
                      .where((account) => account.id != _from?.id)
                      .toList(),
                  accent: _accent,
                  onChanged: (account) => setState(() => _to = account),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _details,
                  decoration: const InputDecoration(labelText: 'Details'),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    _date == null
                        ? 'Optional date'
                        : DateFormat('MMM d, yyyy').format(_date!),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Transfer money'),
                ),
              ],
            ),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  const _AccountSelector({
    required this.label,
    required this.selected,
    required this.accounts,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final FinancialAccount? selected;
  final List<FinancialAccount> accounts;
  final Color accent;
  final ValueChanged<FinancialAccount> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        for (final account in accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onChanged(account),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected?.id == account.id
                      ? accent.withValues(alpha: 0.14)
                      : theme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected?.id == account.id ? accent : theme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconFor(account.type),
                      color: selected?.id == account.id
                          ? accent
                          : theme.mutedForeground,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (account.institution?.isNotEmpty ?? false)
                            Text(
                              account.institution!,
                              style: TextStyle(
                                color: theme.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${account.currency} ${account.currentBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: selected?.id == account.id
                            ? accent
                            : theme.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String type) => switch (type) {
    'bank' => Icons.account_balance_outlined,
    'cash' => Icons.payments_outlined,
    'trading' => Icons.show_chart_rounded,
    _ => Icons.account_balance_wallet_outlined,
  };
}
