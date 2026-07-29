import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import 'financial_history_page.dart';

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

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TransactionRepository _repo;

  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _details = TextEditingController();
  final _accountName = TextEditingController();
  final _institution = TextEditingController();
  final _openingBalance = TextEditingController();

  DateTime? _selectedDate;
  FinancialAccount? _selectedAccount;
  FinancialAccount? _destinationAccount;
  String _accountType = 'ewallet';
  String _currency = 'MYR';
  _SplitMode _splitMode = _SplitMode.exact;

  List<FinancialAccount> _accounts = [];
  List<FinanceTag> _incomeTags = [];
  List<FinanceTag> _expenseTags = [];
  List<TransactionModel> _recurring = [];
  List<Budget> _budgets = [];
  final List<_SplitDraft> _splits = [_SplitDraft()];
  bool _isLoading = true;
  bool _isSaving = false;

  static const _incomeAccent = Color(0xFF5F8787);
  static const _expenseAccent = Color(0xFFD87943);
  static const _transferAccent = Color(0xFF5277C3);

  @override
  void initState() {
    super.initState();
    _repo = TransactionRepository(Supabase.instance.client);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(_resetEntryFields);
    });
    Future.microtask(_loadFinanceData);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      final accounts = await _repo.getAccounts();
      final incomeTags = await _repo.getTags('income');
      final expenseTags = await _repo.getTags('expense');
      final recurring = await _repo.getTransactions(recurringOnly: true);
      final budgets = await _repo.getBudgets();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _incomeTags = incomeTags;
        _expenseTags = expenseTags;
        _recurring = recurring;
        _budgets = budgets;
        _selectedAccount ??= accounts.isEmpty ? null : accounts.first;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load finance data: $error');
    }
  }

  void _resetEntryFields() {
    _amount.clear();
    _merchant.clear();
    _details.clear();
    _selectedDate = null;
    _destinationAccount = null;
    for (final split in _splits) {
      split.dispose();
    }
    _splits
      ..clear()
      ..add(_SplitDraft());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.archivumTheme.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate(Color accent) async {
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
    final accent = type == TransactionType.income ? _incomeAccent : _expenseAccent;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add tag'),
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
          title: const Text('Create account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _accountName,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _institution,
                  decoration: const InputDecoration(
                    labelText: 'Institution',
                    hintText: 'MAE, TNG, MT4',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _accountType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(value: 'ewallet', child: Text('E-wallet')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'trading', child: Text('Trading')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => _accountType = value ?? 'ewallet'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: const [
                    DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => _currency = value ?? 'MYR'),
                ),
                TextField(
                  controller: _openingBalance,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Opening balance'),
                ),
              ],
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionSplit> _buildSplits(double amount) {
    final drafts = _splits.where((split) => split.tag != null).toList();
    if (drafts.isEmpty) throw Exception('Select at least one tag');

    if (_splitMode == _SplitMode.exact) {
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
    final splits = <TransactionSplit>[];
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final percent = double.tryParse(draft.percent.text.trim()) ?? 0;
      final cents = i == drafts.length - 1
          ? amountCents - allocated
          : (amountCents * percent / 100).round();
      allocated += cents;
      splits.add(
        TransactionSplit(
          tagId: draft.tag!.id,
          tagText: draft.tag!.text,
          amount: cents / 100,
        ),
      );
    }
    return splits;
  }

  Future<void> _saveTransaction(
    TransactionType type, {
    bool recurring = false,
  }) async {
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
      if (type == TransactionType.transfer) {
        if (_destinationAccount == null) {
          throw Exception('Select a destination account');
        }
        await _repo.createTransfer(
          fromAccountId: _selectedAccount!.id!,
          toAccountId: _destinationAccount!.id!,
          amount: amount,
          details: _details.text.trim(),
          date: _selectedDate,
        );
      } else {
        await _repo.createTransaction(
          TransactionModel(
            id: '',
            accountId: _selectedAccount!.id,
            type: type,
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
      }
      if (!mounted) return;
      setState(_resetEntryFields);
      await _loadFinanceData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(recurring ? 'Recurring expense saved' : 'Transaction saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showRecurringDrawer() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                'Recurring expenses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_recurring.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No recurring expense templates yet.'),
                ),
              for (final template in _recurring)
                ListTile(
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
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Expense inserted')),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBudgetDialog() async {
    FinanceTag? tag = _expenseTags.isEmpty ? null : _expenseTags.first;
    final limit = TextEditingController();
    DateTime start = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime end = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FinanceTag>(
                initialValue: tag,
                decoration: const InputDecoration(labelText: 'Expense tag'),
                items: _expenseTags
                    .map((tag) => DropdownMenuItem(value: tag, child: Text(tag.text)))
                    .toList(),
                onChanged: (value) => setDialogState(() => tag = value),
              ),
              TextField(
                controller: limit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Limit amount'),
              ),
              const SizedBox(height: 12),
              Text(
                '${DateFormat('MMM d, yyyy').format(start)} - '
                '${DateFormat('MMM d, yyyy').format(end)}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedTag = tag;
                final amount = double.tryParse(limit.text.trim());
                if (selectedTag == null || amount == null || amount <= 0) return;
                await _repo.createBudget(
                  Budget(
                    tagId: selectedTag.id,
                    tagText: selectedTag.text,
                    limitAmount: amount,
                    period: 'monthly',
                    startDate: start,
                    endDate: end,
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                await _loadFinanceData();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    limit.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final activeAccent = switch (_tabController.index) {
      1 => _incomeAccent,
      2 => _transferAccent,
      _ => _expenseAccent,
    };

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _Header(
                    accent: activeAccent,
                    onAccountAdd: _showAccountDialog,
                    onRecurringTap: _showRecurringDrawer,
                    onHistoryTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FinancialHistoryPage(),
                      ),
                    ),
                  ),
                  _AccountStrip(
                    accounts: _accounts,
                    selected: _selectedAccount,
                    onChanged: (account) => setState(() {
                      _selectedAccount = account;
                      if (_destinationAccount?.id == account?.id) {
                        _destinationAccount = null;
                      }
                    }),
                  ),
                  _TabSwitcher(controller: _tabController, accent: activeAccent),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _EntryForm(
                          type: TransactionType.expense,
                          accent: _expenseAccent,
                          amount: _amount,
                          merchant: _merchant,
                          details: _details,
                          date: _selectedDate,
                          tags: _expenseTags,
                          splitMode: _splitMode,
                          splits: _splits,
                          isSaving: _isSaving,
                          onDateTap: () => _pickDate(_expenseAccent),
                          onAddTag: () => _showAddTagDialog(TransactionType.expense),
                          onAddSplit: () => setState(() => _splits.add(_SplitDraft())),
                          onRemoveSplit: (draft) => setState(() {
                            draft.dispose();
                            _splits.remove(draft);
                          }),
                          onSplitModeChanged: (mode) =>
                              setState(() => _splitMode = mode),
                          onSave: () => _saveTransaction(TransactionType.expense),
                          onSaveRecurring: () => _saveTransaction(
                            TransactionType.expense,
                            recurring: true,
                          ),
                        ),
                        _EntryForm(
                          type: TransactionType.income,
                          accent: _incomeAccent,
                          amount: _amount,
                          merchant: _merchant,
                          details: _details,
                          date: _selectedDate,
                          tags: _incomeTags,
                          splitMode: _splitMode,
                          splits: _splits,
                          isSaving: _isSaving,
                          onDateTap: () => _pickDate(_incomeAccent),
                          onAddTag: () => _showAddTagDialog(TransactionType.income),
                          onAddSplit: () => setState(() => _splits.add(_SplitDraft())),
                          onRemoveSplit: (draft) => setState(() {
                            draft.dispose();
                            _splits.remove(draft);
                          }),
                          onSplitModeChanged: (mode) =>
                              setState(() => _splitMode = mode),
                          onSave: () => _saveTransaction(TransactionType.income),
                        ),
                        _TransferForm(
                          accent: _transferAccent,
                          amount: _amount,
                          details: _details,
                          date: _selectedDate,
                          accounts: _accounts
                              .where((account) => account.id != _selectedAccount?.id)
                              .toList(),
                          destination: _destinationAccount,
                          isSaving: _isSaving,
                          onDestinationChanged: (account) =>
                              setState(() => _destinationAccount = account),
                          onDateTap: () => _pickDate(_transferAccent),
                          onSave: () => _saveTransaction(TransactionType.transfer),
                        ),
                      ],
                    ),
                  ),
                  _BudgetStrip(
                    budgets: _budgets,
                    onCreateBudget: _showBudgetDialog,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.accent,
    required this.onAccountAdd,
    required this.onRecurringTap,
    required this.onHistoryTap,
  });

  final Color accent;
  final VoidCallback onAccountAdd;
  final VoidCallback onRecurringTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Finance',
              style: TextStyle(
                color: theme.foreground,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(onPressed: onRecurringTap, icon: const Icon(Icons.repeat)),
          IconButton(onPressed: onHistoryTap, icon: const Icon(Icons.history)),
          IconButton(onPressed: onAccountAdd, icon: const Icon(Icons.add_card)),
        ],
      ),
    );
  }
}

class _AccountStrip extends StatelessWidget {
  const _AccountStrip({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  final List<FinancialAccount> accounts;
  final FinancialAccount? selected;
  final ValueChanged<FinancialAccount?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Create a finance account to start logging transactions.'),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final account = accounts[index];
          final isSelected = selected?.id == account.id;
          return ChoiceChip(
            selected: isSelected,
            label: SizedBox(
              width: 150,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${account.currency} ${account.currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            onSelected: (_) => onChanged(account),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: accounts.length,
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.controller, required this.accent});

  final TabController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: accent,
      tabs: const [
        Tab(text: 'Expense'),
        Tab(text: 'Income'),
        Tab(text: 'Transfer'),
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
    required this.tags,
    required this.splitMode,
    required this.splits,
    required this.isSaving,
    required this.onDateTap,
    required this.onAddTag,
    required this.onAddSplit,
    required this.onRemoveSplit,
    required this.onSplitModeChanged,
    required this.onSave,
    this.onSaveRecurring,
  });

  final TransactionType type;
  final Color accent;
  final TextEditingController amount;
  final TextEditingController merchant;
  final TextEditingController details;
  final DateTime? date;
  final List<FinanceTag> tags;
  final _SplitMode splitMode;
  final List<_SplitDraft> splits;
  final bool isSaving;
  final VoidCallback onDateTap;
  final VoidCallback onAddTag;
  final VoidCallback onAddSplit;
  final ValueChanged<_SplitDraft> onRemoveSplit;
  final ValueChanged<_SplitMode> onSplitModeChanged;
  final VoidCallback onSave;
  final VoidCallback? onSaveRecurring;

  @override
  Widget build(BuildContext context) {
    final isExpense = type == TransactionType.expense;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        TextField(
          controller: merchant,
          decoration: InputDecoration(
            labelText: isExpense ? 'Merchant' : 'Source',
          ),
        ),
        TextField(
          controller: details,
          decoration: const InputDecoration(labelText: 'Details'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDateTap,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            date == null ? 'Optional date' : DateFormat('MMM d, yyyy').format(date!),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_SplitMode>(
          segments: const [
            ButtonSegment(value: _SplitMode.exact, label: Text('Exact')),
            ButtonSegment(value: _SplitMode.percent, label: Text('Percent')),
          ],
          selected: {splitMode},
          onSelectionChanged: (selection) => onSplitModeChanged(selection.first),
        ),
        const SizedBox(height: 10),
        for (final split in splits)
          _SplitRow(
            split: split,
            tags: tags,
            splitMode: splitMode,
            canRemove: splits.length > 1,
            onRemove: () => onRemoveSplit(split),
          ),
        Row(
          children: [
            TextButton.icon(
              onPressed: onAddSplit,
              icon: const Icon(Icons.call_split),
              label: const Text('Split'),
            ),
            TextButton.icon(
              onPressed: onAddTag,
              icon: const Icon(Icons.add),
              label: const Text('Add tag'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isSaving ? null : onSave,
          style: ElevatedButton.styleFrom(backgroundColor: accent),
          child: Text(isSaving ? 'Saving...' : 'Save ${isExpense ? 'expense' : 'income'}'),
        ),
        if (onSaveRecurring != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isSaving ? null : onSaveRecurring,
            icon: const Icon(Icons.repeat),
            label: const Text('Save as recurring shortcut'),
          ),
        ],
      ],
    );
  }
}

class _SplitRow extends StatefulWidget {
  const _SplitRow({
    required this.split,
    required this.tags,
    required this.splitMode,
    required this.canRemove,
    required this.onRemove,
  });

  final _SplitDraft split;
  final List<FinanceTag> tags;
  final _SplitMode splitMode;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_SplitRow> createState() => _SplitRowState();
}

class _SplitRowState extends State<_SplitRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<FinanceTag>(
            initialValue: widget.tags.contains(widget.split.tag)
                ? widget.split.tag
                : null,
            decoration: const InputDecoration(labelText: 'Tag'),
            items: widget.tags
                .map((tag) => DropdownMenuItem(value: tag, child: Text(tag.text)))
                .toList(),
            onChanged: (value) => setState(() => widget.split.tag = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: widget.splitMode == _SplitMode.exact
                ? widget.split.amount
                : widget.split.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.splitMode == _SplitMode.exact ? 'Amount' : '%',
            ),
          ),
        ),
        IconButton(
          onPressed: widget.canRemove ? widget.onRemove : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
    );
  }
}

class _TransferForm extends StatelessWidget {
  const _TransferForm({
    required this.accent,
    required this.amount,
    required this.details,
    required this.date,
    required this.accounts,
    required this.destination,
    required this.isSaving,
    required this.onDestinationChanged,
    required this.onDateTap,
    required this.onSave,
  });

  final Color accent;
  final TextEditingController amount;
  final TextEditingController details;
  final DateTime? date;
  final List<FinancialAccount> accounts;
  final FinancialAccount? destination;
  final bool isSaving;
  final ValueChanged<FinancialAccount?> onDestinationChanged;
  final VoidCallback onDateTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        DropdownButtonFormField<FinancialAccount>(
          initialValue: destination,
          decoration: const InputDecoration(labelText: 'To account'),
          items: accounts
              .map(
                (account) =>
                    DropdownMenuItem(value: account, child: Text(account.name)),
              )
              .toList(),
          onChanged: onDestinationChanged,
        ),
        TextField(
          controller: details,
          decoration: const InputDecoration(labelText: 'Details'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDateTap,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            date == null ? 'Optional date' : DateFormat('MMM d, yyyy').format(date!),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isSaving ? null : onSave,
          style: ElevatedButton.styleFrom(backgroundColor: accent),
          child: Text(isSaving ? 'Saving...' : 'Save transfer'),
        ),
      ],
    );
  }
}

class _BudgetStrip extends StatelessWidget {
  const _BudgetStrip({required this.budgets, required this.onCreateBudget});

  final List<Budget> budgets;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onCreateBudget,
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Budget'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: budgets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final pct = budget.limitAmount <= 0
                    ? 0.0
                    : (budget.usedAmount / budget.limitAmount).clamp(0.0, 1.0);
                return SizedBox(
                  width: 170,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(budget.tagText, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: pct),
                          const SizedBox(height: 4),
                          Text(
                            '${budget.usedAmount.toStringAsFixed(2)} / ${budget.limitAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
