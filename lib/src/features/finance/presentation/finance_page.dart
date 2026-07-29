import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import 'account_nodes_page.dart';
import 'financial_history_page.dart';
import 'transfer_page.dart';

enum _SplitMode { exact, percent }

class _SplitDraft {
  FinanceTag? tag;
  final TextEditingController amount = TextEditingController();
  final TextEditingController percent = TextEditingController();

  void dispose() {
    amount.dispose();
    percent.dispose();
  }
}

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late final TransactionRepository _repo;
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _details = TextEditingController();
  final _accountName = TextEditingController();
  final _institution = TextEditingController();
  final _openingBalance = TextEditingController();
  final List<_SplitDraft> _splits = [_SplitDraft()];

  TransactionType _entryType = TransactionType.expense;
  DateTime? _selectedDate;
  FinancialAccount? _selectedAccount;
  String _accountType = 'ewallet';
  String _currency = 'MYR';
  _SplitMode _splitMode = _SplitMode.exact;
  List<FinancialAccount> _accounts = [];
  List<FinanceTag> _incomeTags = [];
  List<FinanceTag> _expenseTags = [];
  List<TransactionModel> _recurring = [];
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isIncome => _entryType == TransactionType.income;

  Color get _accent => _isIncome
      ? _FinanceColors.secondary
      : _entryType == TransactionType.transfer
      ? _FinanceColors.tertiary
      : _FinanceColors.primary;

  @override
  void initState() {
    super.initState();
    _repo = TransactionRepository(Supabase.instance.client);
    Future.microtask(_loadFinanceData);
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _details.dispose();
    _accountName.dispose();
    _institution.dispose();
    _openingBalance.dispose();
    for (final split in _splits) {
      split.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    try {
      final values = await Future.wait([
        _repo.getAccounts(),
        _repo.getTags('income'),
        _repo.getTags('expense'),
        _repo.getTransactions(recurringOnly: true),
        _repo.getTransactions(),
      ]);
      if (!mounted) return;
      final accounts = values[0] as List<FinancialAccount>;
      setState(() {
        _accounts = accounts;
        _incomeTags = values[1] as List<FinanceTag>;
        _expenseTags = values[2] as List<FinanceTag>;
        _recurring = values[3] as List<TransactionModel>;
        _transactions = values[4] as List<TransactionModel>;
        _selectedAccount =
            accounts.any((account) => account.id == _selectedAccount?.id)
            ? accounts.firstWhere(
                (account) => account.id == _selectedAccount!.id,
              )
            : accounts.isEmpty
            ? null
            : accounts.first;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(AppError.from(error, stackTrace).message);
    }
  }

  void _resetEntryFields() {
    _amount.clear();
    _merchant.clear();
    _details.clear();
    _selectedDate = null;
    for (final split in _splits) {
      split.dispose();
    }
    _splits
      ..clear()
      ..add(_SplitDraft());
    _splitMode = _SplitMode.exact;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _FinanceColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _showAddTagDialog(TransactionType type) async {
    final controller = TextEditingController();
    final accent = type == TransactionType.income
        ? _FinanceColors.secondary
        : _FinanceColors.primary;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _FinanceColors.surfaceHigh,
        title: const Text('Add classifier'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Tag name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final tag = await _repo.addTag(
                text,
                type == TransactionType.income ? 'income' : 'expense',
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {
                if (type == TransactionType.income) {
                  _incomeTags.add(tag);
                } else {
                  _expenseTags.add(tag);
                }
                _splits.first.tag = tag;
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showAccountDialog() async {
    _accountName.clear();
    _institution.clear();
    _openingBalance.clear();
    _accountType = 'ewallet';
    _currency = 'MYR';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _FinanceColors.surfaceHigh,
          insetPadding: const EdgeInsets.all(24),
          title: const Text('Link account node'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _accountName,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _institution,
                    decoration: const InputDecoration(
                      labelText: 'Institution',
                      hintText: 'MAE, TNG, MT4',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _accountType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'bank', child: Text('Bank')),
                      DropdownMenuItem(
                        value: 'ewallet',
                        child: Text('E-wallet'),
                      ),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(
                        value: 'trading',
                        child: Text('Trading'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => _accountType = value ?? 'ewallet'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: const [
                      DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => _currency = value ?? 'MYR'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _openingBalance,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Opening balance',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _accountName.text.trim();
                if (name.isEmpty) return;
                final account = await _repo.createAccount(
                  FinancialAccount(
                    name: name,
                    type: _accountType,
                    institution: _institution.text.trim(),
                    currency: _currency,
                    openingBalance:
                        double.tryParse(_openingBalance.text.trim()) ?? 0,
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {
                  _accounts.insert(0, account);
                  _selectedAccount = account;
                });
                await _loadFinanceData();
              },
              child: const Text('Link'),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionSplit> _buildSplits(double amount) {
    final drafts = _splits.where((split) => split.tag != null).toList();
    if (drafts.isEmpty) throw AppError.validation('Select at least one tag.');
    if (_splitMode == _SplitMode.exact || drafts.length == 1) {
      if (drafts.length == 1 && drafts.first.amount.text.trim().isEmpty) {
        return [
          TransactionSplit(
            tagId: drafts.first.tag!.id,
            tagText: drafts.first.tag!.text,
            amount: amount,
          ),
        ];
      }
      return drafts
          .map(
            (draft) => TransactionSplit(
              tagId: draft.tag!.id,
              tagText: draft.tag!.text,
              amount: double.tryParse(draft.amount.text.trim()) ?? 0,
            ),
          )
          .toList();
    }

    final amountCents = (amount * 100).round();
    var allocated = 0;
    return List.generate(drafts.length, (index) {
      final draft = drafts[index];
      final cents = index == drafts.length - 1
          ? amountCents - allocated
          : (amountCents *
                    (double.tryParse(draft.percent.text.trim()) ?? 0) /
                    100)
                .round();
      allocated += cents;
      return TransactionSplit(
        tagId: draft.tag!.id,
        tagText: draft.tag!.text,
        amount: cents / 100,
      );
    });
  }

  Future<void> _saveTransaction({bool recurring = false}) async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Create or select an account first');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _repo.createTransaction(
        TransactionModel(
          id: '',
          accountId: _selectedAccount!.id,
          type: _entryType,
          amount: amount,
          merchant: _merchant.text.trim().isEmpty
              ? null
              : _merchant.text.trim(),
          details: _details.text.trim(),
          date: _selectedDate,
          recurring: recurring,
          splits: _buildSplits(amount),
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(_resetEntryFields);
      await _loadFinanceData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recurring ? 'Recurring expense saved' : 'Transaction committed',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error, stackTrace) {
      if (mounted) _showError(AppError.from(error, stackTrace).message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showRecurringDrawer() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _FinanceColors.surfaceHigh,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text(
              'Recurring expenses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (_recurring.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No recurring expense templates yet.'),
              ),
            for (final template in _recurring)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat_rounded),
                title: Text(template.merchant ?? template.details),
                subtitle: Text(template.tagLabel),
                trailing: Text(
                  '${template.accountCurrency ?? 'MYR'} ${template.amount.toStringAsFixed(2)}',
                ),
                onTap: () async {
                  await _repo.cloneRecurringTransaction(template);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await _loadFinanceData();
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Expense inserted')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTransfer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransferPage()),
    );
    if (mounted) await _loadFinanceData();
  }

  Future<void> _openNodes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountNodesPage()),
    );
    if (mounted) await _loadFinanceData();
  }

  @override
  Widget build(BuildContext context) {
    final tags = _isIncome ? _incomeTags : _expenseTags;
    return Scaffold(
      backgroundColor: _FinanceColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _FinanceBackdrop()),
          SafeArea(
            bottom: false,
            child: _isLoading
                ? const _FinanceLoading()
                : RefreshIndicator(
                    color: _FinanceColors.primary,
                    backgroundColor: _FinanceColors.surfaceHigh,
                    onRefresh: _loadFinanceData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 118),
                      children: [
                        _Header(
                          onAccountAdd: _showAccountDialog,
                          onRecurringTap: _showRecurringDrawer,
                          onHistoryTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FinancialHistoryPage(),
                            ),
                          ),
                          onTransferTap: _openTransfer,
                        ),
                        const SizedBox(height: 24),
                        _AccountStrip(
                          accounts: _accounts,
                          selected: _selectedAccount,
                          onChanged: (account) =>
                              setState(() => _selectedAccount = account),
                          onViewAll: _openNodes,
                          onAdd: _showAccountDialog,
                        ),
                        const SizedBox(height: 28),
                        const _TransactionHeading(),
                        const SizedBox(height: 16),
                        _EntryForm(
                          type: _entryType,
                          accent: _accent,
                          amount: _amount,
                          merchant: _merchant,
                          details: _details,
                          date: _selectedDate,
                          selectedAccount: _selectedAccount,
                          accounts: _accounts,
                          tags: tags,
                          splitMode: _splitMode,
                          splits: _splits,
                          isSaving: _isSaving,
                          onTypeChanged: (type) {
                            if (type == TransactionType.transfer) {
                              _openTransfer();
                              return;
                            }
                            setState(() {
                              _entryType = type;
                              _resetEntryFields();
                            });
                          },
                          onAccountChanged: (account) =>
                              setState(() => _selectedAccount = account),
                          onDateTap: _pickDate,
                          onAddTag: () => _showAddTagDialog(_entryType),
                          onAddSplit: () =>
                              setState(() => _splits.add(_SplitDraft())),
                          onRemoveSplit: (draft) => setState(() {
                            draft.dispose();
                            _splits.remove(draft);
                          }),
                          onSplitModeChanged: (mode) =>
                              setState(() => _splitMode = mode),
                          onTagChanged: () => setState(() {}),
                          onSave: () => _saveTransaction(),
                          onSaveRecurring: _isIncome
                              ? null
                              : () => _saveTransaction(recurring: true),
                        ),
                        const SizedBox(height: 28),
                        _Timeline(
                          transactions: _transactions.take(8).toList(),
                          incomeTotal: _incomeTotal,
                          expenseTotal: _expenseTotal,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double get _incomeTotal => _transactions
      .where((transaction) => transaction.type == TransactionType.income)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get _expenseTotal => _transactions
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

class _FinanceColors {
  static const background = Color(0xFF0A0A12);
  static const surface = Color(0xFF141422);
  static const surfaceLow = Color(0xFF111118);
  static const surfaceHigh = Color(0xFF1E1E30);
  static const surfaceHighest = Color(0xFF28283E);
  static const primary = Color(0xFFFF2D78);
  static const primarySoft = Color(0xFFFF80AA);
  static const secondary = Color(0xFF00FFCC);
  static const tertiary = Color(0xFFFFE04A);
  static const foreground = Color(0xFFE8E0F0);
  static const muted = Color(0xFFA098B0);
  static const outline = Color(0xFF302840);
  static const error = Color(0xFFFF4444);
  static const grid = Color(0x22FFFFFF);
}

class _FinanceBackdrop extends StatelessWidget {
  const _FinanceBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _FinanceColors.background,
        gradient: RadialGradient(
          center: const Alignment(0.72, -1.0),
          radius: 1.05,
          colors: [
            _FinanceColors.primary.withValues(alpha: 0.1),
            _FinanceColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: const CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _FinanceColors.grid
      ..strokeWidth = 1;
    const gap = 30.0;

    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onAccountAdd,
    required this.onRecurringTap,
    required this.onHistoryTap,
    required this.onTransferTap,
  });

  final VoidCallback onAccountAdd;
  final VoidCallback onRecurringTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onTransferTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _FinanceColors.surfaceHighest,
            border: Border.all(
              color: _FinanceColors.primary.withValues(alpha: 0.42),
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/archivum_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance_wallet_rounded,
                color: _FinanceColors.primarySoft,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'ARCHIVUM',
            style: TextStyle(
              color: _FinanceColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: _FinanceColors.primary, blurRadius: 8)],
            ),
          ),
        ),
        _HeaderIcon(icon: Icons.swap_horiz_rounded, onTap: onTransferTap),
        _HeaderIcon(icon: Icons.repeat_rounded, onTap: onRecurringTap),
        _HeaderIcon(icon: Icons.history_rounded, onTap: onHistoryTap),
        _HeaderIcon(icon: Icons.add_card_outlined, onTap: onAccountAdd),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      color: _FinanceColors.muted,
      icon: Icon(icon, size: 21),
    );
  }
}

class _AccountStrip extends StatelessWidget {
  const _AccountStrip({
    required this.accounts,
    required this.selected,
    required this.onChanged,
    required this.onViewAll,
    required this.onAdd,
  });

  final List<FinancialAccount> accounts;
  final FinancialAccount? selected;
  final ValueChanged<FinancialAccount?> onChanged;
  final VoidCallback onViewAll;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Text(
                'ACTIVE NODES',
                style: TextStyle(
                  color: _FinanceColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 10),
        if (accounts.isEmpty)
          _EmptyAccountCard(onAdd: onAdd)
        else
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: accounts.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == accounts.length) return _AddNodeCard(onTap: onAdd);
                final account = accounts[index];
                return _AccountNodeCard(
                  account: account,
                  isSelected: selected?.id == account.id,
                  onTap: () => onChanged(account),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyAccountCard extends StatelessWidget {
  const _EmptyAccountCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _GlassButton(
      onTap: onAdd,
      borderColor: _FinanceColors.primary.withValues(alpha: 0.28),
      child: const SizedBox(
        height: 98,
        child: Center(
          child: Text(
            'Create a finance account to start logging transactions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _FinanceColors.muted),
          ),
        ),
      ),
    );
  }
}

class _AccountNodeCard extends StatelessWidget {
  const _AccountNodeCard({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  final FinancialAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? _FinanceColors.primary
        : _FinanceColors.secondary;
    return SizedBox(
      width: 172,
      child: _GlassButton(
        onTap: onTap,
        borderColor: isSelected
            ? _FinanceColors.primary.withValues(alpha: 0.38)
            : _FinanceColors.outline.withValues(alpha: 0.56),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForAccount(account.type), color: accent, size: 22),
                const Spacer(),
                Text(
                  _nodeType(account),
                  style: const TextStyle(
                    color: _FinanceColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'BALANCE',
              style: TextStyle(
                color: _FinanceColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${account.currency} ${account.currentBalance.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? _FinanceColors.primarySoft
                    : _FinanceColors.foreground,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                shadows: isSelected
                    ? const [
                        Shadow(color: _FinanceColors.primary, blurRadius: 8),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _FinanceColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddNodeCard extends StatelessWidget {
  const _AddNodeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _FinanceColors.background.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _FinanceColors.outline.withValues(alpha: 0.65),
              style: BorderStyle.solid,
            ),
          ),
          child: const Icon(Icons.add_rounded, color: _FinanceColors.muted),
        ),
      ),
    );
  }
}

class _TransactionHeading extends StatelessWidget {
  const _TransactionHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _FinanceColors.outline.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'New Transaction',
            style: TextStyle(
              color: _FinanceColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _FinanceColors.outline.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryForm extends StatelessWidget {
  const _EntryForm({
    required this.type,
    required this.accent,
    required this.amount,
    required this.merchant,
    required this.details,
    required this.date,
    required this.selectedAccount,
    required this.accounts,
    required this.tags,
    required this.splitMode,
    required this.splits,
    required this.isSaving,
    required this.onTypeChanged,
    required this.onAccountChanged,
    required this.onDateTap,
    required this.onAddTag,
    required this.onAddSplit,
    required this.onRemoveSplit,
    required this.onSplitModeChanged,
    required this.onTagChanged,
    required this.onSave,
    this.onSaveRecurring,
  });

  final TransactionType type;
  final Color accent;
  final TextEditingController amount;
  final TextEditingController merchant;
  final TextEditingController details;
  final DateTime? date;
  final FinancialAccount? selectedAccount;
  final List<FinancialAccount> accounts;
  final List<FinanceTag> tags;
  final _SplitMode splitMode;
  final List<_SplitDraft> splits;
  final bool isSaving;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<FinancialAccount?> onAccountChanged;
  final VoidCallback onDateTap;
  final VoidCallback onAddTag;
  final VoidCallback onAddSplit;
  final ValueChanged<_SplitDraft> onRemoveSplit;
  final ValueChanged<_SplitMode> onSplitModeChanged;
  final VoidCallback onTagChanged;
  final VoidCallback onSave;
  final VoidCallback? onSaveRecurring;

  @override
  Widget build(BuildContext context) {
    final isExpense = type == TransactionType.expense;
    final hasMultipleTags =
        splits.where((split) => split.tag != null).length >= 2;
    final effectiveMode = hasMultipleTags ? splitMode : _SplitMode.exact;

    return Column(
      children: [
        _AmountPanel(
          amount: amount,
          type: type,
          accent: accent,
          onTypeChanged: onTypeChanged,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FieldPanel(
                label: 'Source account',
                child: DropdownButtonFormField<FinancialAccount>(
                  initialValue: accounts.contains(selectedAccount)
                      ? selectedAccount
                      : null,
                  isExpanded: true,
                  decoration: _inputDecoration('Select node'),
                  dropdownColor: _FinanceColors.surfaceHigh,
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account,
                          child: Text(account.name),
                        ),
                      )
                      .toList(),
                  onChanged: onAccountChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FieldPanel(
                label: 'Date epoch',
                child: OutlinedButton.icon(
                  onPressed: onDateTap,
                  icon: const Icon(Icons.calendar_today_outlined, size: 17),
                  label: Text(
                    date == null
                        ? 'Today'
                        : DateFormat('MMM d, yyyy').format(date!),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _FinanceColors.foreground,
                    side: BorderSide(
                      color: _FinanceColors.outline.withValues(alpha: 0.8),
                    ),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FieldPanel(
          label: isExpense ? 'Merchant' : 'Source',
          child: TextField(
            controller: merchant,
            decoration: _inputDecoration(
              isExpense ? 'Merchant or payee' : 'Income source',
            ),
          ),
        ),
        const SizedBox(height: 14),
        _FieldPanel(
          label: 'Details',
          child: TextField(
            controller: details,
            minLines: 1,
            maxLines: 2,
            decoration: _inputDecoration('Optional notes'),
          ),
        ),
        const SizedBox(height: 14),
        _TagPanel(
          tags: tags,
          splits: splits,
          splitMode: effectiveMode,
          canChooseSplitMode: hasMultipleTags,
          onAddTag: onAddTag,
          onAddSplit: onAddSplit,
          onRemoveSplit: onRemoveSplit,
          onSplitModeChanged: onSplitModeChanged,
          onTagChanged: onTagChanged,
        ),
        const SizedBox(height: 18),
        _CommitButton(
          isSaving: isSaving,
          label: isSaving
              ? 'Committing...'
              : 'Commit ${isExpense ? 'expense' : 'income'}',
          onTap: isSaving ? null : onSave,
          accent: accent,
        ),
        if (onSaveRecurring != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isSaving ? null : onSaveRecurring,
            icon: const Icon(Icons.repeat_rounded),
            label: const Text('Save as recurring shortcut'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _FinanceColors.muted,
              minimumSize: const Size.fromHeight(46),
              side: BorderSide(
                color: _FinanceColors.outline.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({
    required this.amount,
    required this.type,
    required this.accent,
    required this.onTypeChanged,
  });

  final TextEditingController amount;
  final TransactionType type;
  final Color accent;
  final ValueChanged<TransactionType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      borderColor: accent.withValues(alpha: 0.28),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        children: [
          const Text(
            'AMOUNT',
            style: TextStyle(
              color: _FinanceColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: _FinanceColors.primarySoft,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _FinanceColors.foreground,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypeChip(
                label: 'Expense',
                type: TransactionType.expense,
                selectedType: type,
                onSelected: onTypeChanged,
              ),
              _TypeChip(
                label: 'Income',
                type: TransactionType.income,
                selectedType: type,
                onSelected: onTypeChanged,
              ),
              _TypeChip(
                label: 'Transfer',
                type: TransactionType.transfer,
                selectedType: type,
                onSelected: onTypeChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.type,
    required this.selectedType,
    required this.onSelected,
  });

  final String label;
  final TransactionType type;
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = type == selectedType;
    return InkWell(
      onTap: () => onSelected(type),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _FinanceColors.primary.withValues(alpha: 0.12)
              : _FinanceColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _FinanceColors.primary : _FinanceColors.outline,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? _FinanceColors.primary : _FinanceColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FieldPanel extends StatelessWidget {
  const _FieldPanel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      borderColor: _FinanceColors.outline.withValues(alpha: 0.42),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _FinanceColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TagPanel extends StatelessWidget {
  const _TagPanel({
    required this.tags,
    required this.splits,
    required this.splitMode,
    required this.canChooseSplitMode,
    required this.onAddTag,
    required this.onAddSplit,
    required this.onRemoveSplit,
    required this.onSplitModeChanged,
    required this.onTagChanged,
  });

  final List<FinanceTag> tags;
  final List<_SplitDraft> splits;
  final _SplitMode splitMode;
  final bool canChooseSplitMode;
  final VoidCallback onAddTag;
  final VoidCallback onAddSplit;
  final ValueChanged<_SplitDraft> onRemoveSplit;
  final ValueChanged<_SplitMode> onSplitModeChanged;
  final VoidCallback onTagChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      borderColor: _FinanceColors.outline.withValues(alpha: 0.42),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'CLASSIFIERS & SUB-DIVISIONS',
                  style: TextStyle(
                    color: _FinanceColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAddSplit,
                tooltip: 'Add split',
                icon: const Icon(
                  Icons.settings_input_component_rounded,
                  color: _FinanceColors.secondary,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final split in splits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SplitRow(
                split: split,
                tags: tags,
                splitMode: splitMode,
                canRemove: splits.length > 1,
                onRemove: () => onRemoveSplit(split),
                onTagChanged: onTagChanged,
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallAction(
                icon: Icons.call_split_rounded,
                label: 'Split',
                onTap: onAddSplit,
              ),
              _SmallAction(
                icon: Icons.add_rounded,
                label: 'Attach tag',
                onTap: onAddTag,
              ),
            ],
          ),
          if (canChooseSplitMode) ...[
            const SizedBox(height: 14),
            SegmentedButton<_SplitMode>(
              segments: const [
                ButtonSegment(value: _SplitMode.exact, label: Text('Exact')),
                ButtonSegment(
                  value: _SplitMode.percent,
                  label: Text('Percent'),
                ),
              ],
              selected: {splitMode},
              onSelectionChanged: (selection) =>
                  onSplitModeChanged(selection.first),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.split,
    required this.tags,
    required this.splitMode,
    required this.canRemove,
    required this.onRemove,
    required this.onTagChanged,
  });

  final _SplitDraft split;
  final List<FinanceTag> tags;
  final _SplitMode splitMode;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onTagChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<FinanceTag>(
            initialValue: tags.contains(split.tag) ? split.tag : null,
            decoration: _inputDecoration('Tag'),
            dropdownColor: _FinanceColors.surfaceHigh,
            items: tags
                .map(
                  (tag) => DropdownMenuItem(value: tag, child: Text(tag.text)),
                )
                .toList(),
            onChanged: (value) {
              split.tag = value;
              onTagChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: splitMode == _SplitMode.exact
                ? split.amount
                : split.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              splitMode == _SplitMode.exact ? 'Amount' : '%',
            ),
          ),
        ),
        IconButton(
          onPressed: canRemove ? onRemove : null,
          tooltip: 'Remove split',
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _FinanceColors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _FinanceColors.outline.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _FinanceColors.secondary, size: 14),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: _FinanceColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitButton extends StatelessWidget {
  const _CommitButton({
    required this.isSaving,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final bool isSaving;
  final String label;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _FinanceColors.surfaceHighest,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        shadowColor: accent.withValues(alpha: 0.5),
        elevation: 10,
      ),
      icon: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_rounded),
      label: Text(
        label.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.transactions,
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final List<TransactionModel> transactions;
  final double incomeTotal;
  final double expenseTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Timeline',
                style: TextStyle(
                  color: _FinanceColors.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _TotalPill(
              icon: Icons.arrow_upward_rounded,
              amount: incomeTotal,
              color: _FinanceColors.secondary,
            ),
            const SizedBox(width: 8),
            _TotalPill(
              icon: Icons.arrow_downward_rounded,
              amount: expenseTotal,
              color: _FinanceColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          const _EmptyTimeline()
        else
          for (final transaction in transactions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TimelineTile(transaction: transaction),
            ),
      ],
    );
  }
}

class _TotalPill extends StatelessWidget {
  const _TotalPill({
    required this.icon,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _FinanceColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            _shortMoney(amount),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final color = isTransfer
        ? _FinanceColors.tertiary
        : isIncome
        ? _FinanceColors.secondary
        : _FinanceColors.primary;
    final prefix = isTransfer
        ? transaction.transferSide == TransferSide.in_
              ? '+'
              : '-'
        : isIncome
        ? '+'
        : '-';

    return _GlassPanel(
      borderColor: _FinanceColors.outline.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _FinanceColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _FinanceColors.outline.withValues(alpha: 0.44),
              ),
            ),
            child: Icon(_iconForTransaction(transaction), color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _transactionTitle(transaction),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FinanceColors.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    DateFormat('MMM d').format(transaction.displayDate),
                    if ((transaction.accountName ?? '').isNotEmpty)
                      transaction.accountName!,
                    transaction.tagLabel,
                  ].join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FinanceColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isIncome
                    ? 'RECEIVED'
                    : isTransfer
                    ? 'TRANSFER'
                    : 'SETTLED',
                style: TextStyle(
                  color: color.withValues(alpha: 0.82),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      borderColor: _FinanceColors.outline.withValues(alpha: 0.28),
      child: const SizedBox(
        height: 86,
        child: Center(
          child: Text(
            'No committed transactions yet.',
            style: TextStyle(color: _FinanceColors.muted),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _FinanceColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.child,
    required this.onTap,
    required this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback onTap;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: _GlassPanel(
          borderColor: borderColor,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _FinanceLoading extends StatelessWidget {
  const _FinanceLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _FinanceColors.primary,
        strokeWidth: 2.4,
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _FinanceColors.surfaceLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _FinanceColors.outline.withValues(alpha: 0.72),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _FinanceColors.outline.withValues(alpha: 0.72),
      ),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: _FinanceColors.secondary),
    ),
  );
}

IconData _iconForAccount(String type) => switch (type) {
  'bank' => Icons.account_balance_outlined,
  'cash' => Icons.payments_outlined,
  'trading' => Icons.show_chart_rounded,
  _ => Icons.account_balance_wallet_outlined,
};

IconData _iconForTransaction(TransactionModel transaction) {
  if (transaction.type == TransactionType.transfer) return Icons.swap_horiz;
  if (transaction.type == TransactionType.income) return Icons.work_rounded;
  final label = transaction.tagLabel.toLowerCase();
  if (label.contains('food') || label.contains('dining')) {
    return Icons.restaurant_rounded;
  }
  if (label.contains('transport')) return Icons.directions_car_rounded;
  if (label.contains('housing') || label.contains('rent')) {
    return Icons.home_work_rounded;
  }
  return Icons.bolt_rounded;
}

String _nodeType(FinancialAccount account) {
  if ((account.institution ?? '').isNotEmpty) return account.institution!;
  return account.type.toUpperCase();
}

String _transactionTitle(TransactionModel transaction) {
  if (transaction.merchant?.isNotEmpty == true) return transaction.merchant!;
  if (transaction.details.isNotEmpty) return transaction.details;
  if (transaction.type == TransactionType.transfer) return 'Transfer';
  return 'Transaction';
}

String _shortMoney(double value) {
  if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}
