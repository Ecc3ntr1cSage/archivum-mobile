import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import 'financial_history_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _details = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTag;

  List<String> _incomeTags = [];
  List<String> _expenseTags = [];

  static const Color _incomeAccent = Color(0xFF5F8787);
  static const Color _expenseAccent = Color(0xFFD87943);

  bool get _isIncomeTab => _tabController.index == 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedTag = null;
        _selectedDate = null;
        _amount.clear();
        _details.clear();
      });
    });
    Future.microtask(_loadTags);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amount.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    if (!mounted) return;
    try {
      final repo = TransactionRepository(Supabase.instance.client);
      final fetchedIncomeTags = await repo.getTags('income');
      final fetchedExpenseTags = await repo.getTags('expense');
      if (!mounted) return;
      setState(() {
        if (fetchedIncomeTags.isNotEmpty) {
          _incomeTags = fetchedIncomeTags;
        }
        if (fetchedExpenseTags.isNotEmpty) {
          _expenseTags = fetchedExpenseTags;
        }
      });
    } catch (_) {
      // Keep the UI usable even if tag loading fails.
    }
  }

  Future<void> _pickDate(Color accent) async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(primary: accent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showAddTagDialog(bool isIncome) async {
    final theme = context.archivumTheme;
    final accent = isIncome ? _incomeAccent : _expenseAccent;
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.popover,
          title: Text(
            'Add new tag',
            style: TextStyle(color: theme.popoverForeground),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: theme.foreground),
            decoration: const InputDecoration(hintText: 'Enter tag name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final tagText = controller.text.trim();
                if (tagText.isEmpty) return;

                try {
                  final repo = TransactionRepository(Supabase.instance.client);
                  await repo.addTag(tagText, isIncome ? 'income' : 'expense');
                  if (!context.mounted) return;

                  Navigator.pop(context);
                  if (!mounted) return;
                  setState(() {
                    if (isIncome) {
                      if (!_incomeTags.contains(tagText)) {
                        _incomeTags.add(tagText);
                      }
                    } else {
                      if (!_expenseTags.contains(tagText)) {
                        _expenseTags.add(tagText);
                      }
                    }
                    _selectedTag = tagText;
                  });

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tag added successfully')),
                  );
                } catch (error) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to add tag: $error')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _save(bool isIncome) async {
    final amountText = _amount.text.trim();
    final details = _details.text.trim();
    final tag = _selectedTag ?? 'Other';
    final accent = isIncome ? _incomeAccent : _expenseAccent;

    if (amountText.isEmpty) return;

    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid amount'),
          backgroundColor: context.archivumTheme.destructive,
        ),
      );
      return;
    }

    try {
      final transaction = TransactionModel(
        id: '',
        type: isIncome ? TransactionType.income : TransactionType.expense,
        amount: parsedAmount,
        details: details,
        tag: tag,
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      final repo = TransactionRepository(Supabase.instance.client);
      await repo.createTransaction(transaction);

      setState(() {
        _amount.clear();
        _details.clear();
        _selectedTag = null;
        _selectedDate = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${isIncome ? 'Income' : 'Expense'} logged successfully',
          ),
          backgroundColor: accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: context.archivumTheme.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FinanceHeader(
              activeAccent: _isIncomeTab ? _incomeAccent : _expenseAccent,
            ),
            _FinanceTabs(
              controller: _tabController,
              activeAccent: _isIncomeTab ? _incomeAccent : _expenseAccent,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FinanceFormTab(
                    key: const ValueKey('expense-tab'),
                    title: 'Track an expense',
                    subtitle: 'Capture outgoing money with category and date.',
                    accent: _expenseAccent,
                    icon: Icons.south_east_rounded,
                    amountIcon: Icons.shopping_bag_outlined,
                    actionLabel: 'Log Expense',
                    detailsHint: 'Groceries, utilities, transport',
                    selectedDate: _selectedDate,
                    selectedTag: _selectedTag,
                    amountController: _amount,
                    detailsController: _details,
                    tags: _expenseTags,
                    onDateTap: () => _pickDate(_expenseAccent),
                    onClearDate: () => setState(() => _selectedDate = null),
                    onTagSelected: (tag) => setState(() => _selectedTag = tag),
                    onAddTag: () => _showAddTagDialog(false),
                    onSubmit: () => _save(false),
                  ),
                  _FinanceFormTab(
                    key: const ValueKey('income-tab'),
                    title: 'Record income',
                    subtitle: 'Keep earnings, side income, and payouts tidy.',
                    accent: _incomeAccent,
                    icon: Icons.north_west_rounded,
                    amountIcon: Icons.payments_outlined,
                    actionLabel: 'Log Income',
                    detailsHint: 'Salary, freelance work, dividends',
                    selectedDate: _selectedDate,
                    selectedTag: _selectedTag,
                    amountController: _amount,
                    detailsController: _details,
                    tags: _incomeTags,
                    onDateTap: () => _pickDate(_incomeAccent),
                    onClearDate: () => setState(() => _selectedDate = null),
                    onTagSelected: (tag) => setState(() => _selectedTag = tag),
                    onAddTag: () => _showAddTagDialog(true),
                    onSubmit: () => _save(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({required this.activeAccent});

  final Color activeAccent;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: activeAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: activeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance',
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A calmer ledger for money in and out.',
                  style: TextStyle(color: theme.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceTabs extends StatelessWidget {
  const _FinanceTabs({required this.controller, required this.activeAccent});

  final TabController controller;
  final Color activeAccent;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      color: theme.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.muted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.border),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: activeAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: activeAccent.withValues(alpha: 0.35)),
          ),
          indicatorPadding: const EdgeInsets.all(4),
          dividerColor: Colors.transparent,
          labelColor: activeAccent,
          unselectedLabelColor: theme.mutedForeground,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
    );
  }
}

class _FinanceFormTab extends StatelessWidget {
  const _FinanceFormTab({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.amountIcon,
    required this.actionLabel,
    required this.detailsHint,
    required this.selectedDate,
    required this.selectedTag,
    required this.amountController,
    required this.detailsController,
    required this.tags,
    required this.onDateTap,
    required this.onClearDate,
    required this.onTagSelected,
    required this.onAddTag,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final IconData amountIcon;
  final String actionLabel;
  final String detailsHint;
  final DateTime? selectedDate;
  final String? selectedTag;
  final TextEditingController amountController;
  final TextEditingController detailsController;
  final List<String> tags;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;
  final ValueChanged<String> onTagSelected;
  final VoidCallback onAddTag;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _HeroCard(accent: accent, icon: icon),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: theme.mutedForeground, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _FormSection(
            accent: accent,
            child: Column(
              children: [
                _SectionLabel(label: 'Amount', accent: accent),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Icon(amountIcon, color: accent),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Details', accent: accent),
                const SizedBox(height: 8),
                TextFormField(
                  controller: detailsController,
                  style: TextStyle(color: theme.foreground, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: detailsHint,
                    prefixIcon: Icon(
                      Icons.notes_rounded,
                      color: theme.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Date', accent: accent),
                const SizedBox(height: 8),
                _PickerRow(
                  icon: Icons.calendar_today_outlined,
                  accent: accent,
                  label: selectedDate == null
                      ? 'Optional'
                      : DateFormat('MMM d, yyyy').format(selectedDate!),
                  muted: selectedDate == null,
                  onTap: onDateTap,
                  trailing: selectedDate == null
                      ? Icon(
                          Icons.chevron_right_rounded,
                          color: theme.mutedForeground,
                        )
                      : IconButton(
                          onPressed: onClearDate,
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.mutedForeground,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Tag', accent: accent),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in tags)
                      _TagChip(
                        label: tag,
                        selected: selectedTag == tag,
                        accent: accent,
                        onTap: () => onTagSelected(tag),
                      ),
                    _AddTagChip(accent: accent, onTap: onAddTag),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _HistoryCard(accent: accent),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Money flow',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture the amount, tag it, and keep the ledger clean.',
                  style: TextStyle(
                    color: theme.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.muted,
    required this.onTap,
    required this.trailing,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final bool muted;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.input.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: muted ? theme.mutedForeground : theme.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : theme.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : theme.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : theme.mutedForeground,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: accent, size: 16),
            const SizedBox(width: 6),
            Text(
              'Add tag',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinancialHistoryPage()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.history_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial history',
                    style: TextStyle(
                      color: theme.foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Review and edit previous entries.',
                    style: TextStyle(
                      color: theme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: theme.mutedForeground,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
