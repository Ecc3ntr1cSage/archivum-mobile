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
      backgroundColor: _TransferColors.background,
      appBar: AppBar(
        backgroundColor: _TransferColors.background,
        foregroundColor: _TransferColors.foreground,
        surfaceTintColor: Colors.transparent,
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
                  style: const TextStyle(color: _TransferColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                Text(
                  'All accounts',
                  style: const TextStyle(
                    color: _TransferColors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose where money moves from and where it lands.',
                  style: const TextStyle(color: _TransferColors.muted),
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
                  decoration: _transferInputDecoration('Amount'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _details,
                  decoration: _transferInputDecoration('Details'),
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
                    foregroundColor: Colors.white,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _TransferColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<FinancialAccount>(
          initialValue: accounts.contains(selected) ? selected : null,
          isExpanded: true,
          menuMaxHeight: 320,
          dropdownColor: _TransferColors.surfaceHigh,
          icon: Icon(Icons.unfold_more_rounded, color: accent),
          decoration: _transferInputDecoration('Select account'),
          items: accounts
              .map(
                (account) => DropdownMenuItem(
                  value: account,
                  child: Row(
                    children: [
                      Icon(_iconFor(account.type), color: accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          account.institution?.isNotEmpty ?? false
                              ? '${account.name} · ${account.institution}'
                              : account.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${account.currency} ${account.currentBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _TransferColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }

  IconData _iconFor(String type) => switch (type) {
    'bank' => Icons.account_balance_outlined,
    'cash' => Icons.payments_outlined,
    'credit' => Icons.credit_card_outlined,
    'trading' => Icons.show_chart_rounded,
    _ => Icons.account_balance_wallet_outlined,
  };
}

class _TransferColors {
  static const background = Color(0xFF0B101B);
  static const surface = Color(0xFF121A2A);
  static const surfaceHigh = Color(0xFF1A263B);
  static const foreground = Color(0xFFE8EEF8);
  static const muted = Color(0xFF8E9AAF);
  static const outline = Color(0xFF2B3A54);
}

InputDecoration _transferInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _TransferColors.surface.withValues(alpha: 0.9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _TransferColors.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _TransferColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: _TransferPageState._accent,
        width: 1.5,
      ),
    ),
  );
}
