import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

class AccountNodesPage extends StatefulWidget {
  const AccountNodesPage({super.key});

  @override
  State<AccountNodesPage> createState() => _AccountNodesPageState();
}

class _AccountNodesPageState extends State<AccountNodesPage> {
  late final TransactionRepository _repo;
  final _accountName = TextEditingController();
  final _institution = TextEditingController();
  final _accountInfo = TextEditingController();
  final _openingBalance = TextEditingController();

  List<FinancialAccount> _accounts = [];
  List<FinanceTag> _expenseTags = [];
  List<Budget> _budgets = [];
  String _accountType = 'ewallet';
  String _currency = 'MYR';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repo = TransactionRepository(Supabase.instance.client);
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _accountName.dispose();
    _institution.dispose();
    _accountInfo.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final values = await Future.wait([
        _repo.getAccounts(),
        _repo.getTags('expense'),
        _repo.getBudgets(),
      ]);
      if (!mounted) return;
      setState(() {
        _accounts = values[0] as List<FinancialAccount>;
        _expenseTags = values[1] as List<FinanceTag>;
        _budgets = values[2] as List<Budget>;
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
      SnackBar(
        content: Text(message),
        backgroundColor: _NodeColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAccountDialog() async {
    _accountName.clear();
    _institution.clear();
    _accountInfo.clear();
    _openingBalance.clear();
    _accountType = 'ewallet';
    _currency = 'MYR';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _NodeColors.surfaceHigh,
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
                  TextField(
                    controller: _accountInfo,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Info (optional)',
                      hintText: 'Anything useful about this account',
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
                        value: 'credit',
                        child: Text('Credit card'),
                      ),
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
                await _repo.createAccount(
                  FinancialAccount(
                    name: name,
                    type: _accountType,
                    institution: _institution.text.trim(),
                    info: _accountInfo.text.trim(),
                    currency: _currency,
                    openingBalance:
                        double.tryParse(_openingBalance.text.trim()) ?? 0,
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                await _loadData();
              },
              child: const Text('Link node'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetDialog() async {
    FinanceTag? tag = _expenseTags.isEmpty ? null : _expenseTags.first;
    final limit = TextEditingController();
    final start = DateTime(DateTime.now().year, DateTime.now().month);
    final end = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _NodeColors.surfaceHigh,
          title: const Text('Create budget allocation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FinanceTag>(
                initialValue: tag,
                decoration: const InputDecoration(labelText: 'Expense tag'),
                items: _expenseTags
                    .map(
                      (tag) =>
                          DropdownMenuItem(value: tag, child: Text(tag.text)),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => tag = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Limit amount'),
              ),
              const SizedBox(height: 12),
              Text(
                '${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}',
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
                final amount = double.tryParse(limit.text.trim());
                if (tag == null || amount == null || amount <= 0) return;
                await _repo.createBudget(
                  Budget(
                    tagId: tag!.id,
                    tagText: tag!.text,
                    limitAmount: amount,
                    period: 'monthly',
                    startDate: start,
                    endDate: end,
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                await _loadData();
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
    return Scaffold(
      backgroundColor: _NodeColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAccountDialog,
        backgroundColor: _NodeColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _NodeBackdrop()),
          SafeArea(
            bottom: false,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _NodeColors.primary,
                      strokeWidth: 2.4,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _NodeColors.primary,
                    backgroundColor: _NodeColors.surfaceHigh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                      children: [
                        _Header(totalAccounts: _accounts.length),
                        const SizedBox(height: 24),
                        _AccountGrid(
                          accounts: _accounts,
                          onAdd: _showAccountDialog,
                        ),
                        const SizedBox(height: 32),
                        _BudgetAllocation(
                          budgets: _budgets,
                          onCreateBudget: _showBudgetDialog,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NodeColors {
  static const background = Color(0xFF0A0A12);
  static const surface = Color(0xFF141422);
  static const surfaceHigh = Color(0xFF1E1E30);
  static const primary = Color(0xFFFF2D78);
  static const secondary = Color(0xFF00FFCC);
  static const tertiary = Color(0xFFFFE04A);
  static const foreground = Color(0xFFE8E0F0);
  static const muted = Color(0xFFA098B0);
  static const outline = Color(0xFF302840);
  static const error = Color(0xFFFF4444);
  static const grid = Color(0x1BFFFFFF);
}

class _NodeBackdrop extends StatelessWidget {
  const _NodeBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _NodeColors.background,
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.95),
          radius: 1.05,
          colors: [
            _NodeColors.primary.withValues(alpha: 0.08),
            _NodeColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: const CustomPaint(painter: _NodeGridPainter()),
    );
  }
}

class _NodeGridPainter extends CustomPainter {
  const _NodeGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _NodeColors.grid
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
  const _Header({required this.totalAccounts});

  final int totalAccounts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          color: _NodeColors.foreground,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'ACTIVE NODES',
            style: TextStyle(
              color: _NodeColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$totalAccounts TOTAL',
          style: const TextStyle(
            color: _NodeColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AccountGrid extends StatelessWidget {
  const _AccountGrid({required this.accounts, required this.onAdd});

  final List<FinancialAccount> accounts;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.04,
      ),
      itemCount: accounts.length + 1,
      itemBuilder: (context, index) {
        if (index == accounts.length) return _LinkNodeCard(onTap: onAdd);
        final account = accounts[index];
        return _AccountNode(account: account, isPrimary: index == 0);
      },
    );
  }
}

class _AccountNode extends StatelessWidget {
  const _AccountNode({required this.account, required this.isPrimary});

  final FinancialAccount account;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final accent = isPrimary ? _NodeColors.primary : _NodeColors.secondary;
    return _NodePanel(
      borderColor: accent.withValues(alpha: isPrimary ? 0.36 : 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconForAccount(account.type), color: accent),
              ),
              const Spacer(),
              Text(
                isPrimary ? 'PRIMARY' : account.type.toUpperCase(),
                style: const TextStyle(
                  color: _NodeColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _NodeColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${account.currency} ${account.currentBalance.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: accent.withValues(alpha: 0.9), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkNodeCard extends StatelessWidget {
  const _LinkNodeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _NodeColors.surface.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _NodeColors.outline.withValues(alpha: 0.72),
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: _NodeColors.muted),
            SizedBox(height: 8),
            Text(
              'LINK NODE',
              style: TextStyle(
                color: _NodeColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAllocation extends StatelessWidget {
  const _BudgetAllocation({
    required this.budgets,
    required this.onCreateBudget,
  });

  final List<Budget> budgets;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _NodeColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'BUDGET ALLOCATION',
                style: TextStyle(
                  color: _NodeColors.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onCreateBudget,
              child: const Text('Recalibrate'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (budgets.isEmpty)
          _NodePanel(
            borderColor: _NodeColors.outline.withValues(alpha: 0.32),
            child: const SizedBox(
              height: 92,
              child: Center(
                child: Text(
                  'No active budget allocations yet.',
                  style: TextStyle(color: _NodeColors.muted),
                ),
              ),
            ),
          )
        else
          for (final budget in budgets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BudgetNode(budget: budget),
            ),
      ],
    );
  }
}

class _BudgetNode extends StatelessWidget {
  const _BudgetNode({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final pct = budget.limitAmount <= 0
        ? 0.0
        : (budget.usedAmount / budget.limitAmount).clamp(0.0, 1.0);
    final accent = pct >= 0.82
        ? _NodeColors.primary
        : pct >= 0.55
        ? _NodeColors.tertiary
        : _NodeColors.secondary;
    final remaining = (budget.limitAmount - budget.usedAmount).clamp(
      0.0,
      double.infinity,
    );

    return _NodePanel(
      borderColor: _NodeColors.outline.withValues(alpha: 0.36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.tagText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _NodeColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormat('MMM d').format(budget.startDate)} - ${DateFormat('MMM d').format(budget.endDate)}',
                      style: const TextStyle(
                        color: _NodeColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _NodeColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Remaining: ${budget.currency} ${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: pct >= 0.82
                        ? _NodeColors.primary
                        : _NodeColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Limit: ${budget.currency} ${budget.limitAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _NodeColors.muted,
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

class _NodePanel extends StatelessWidget {
  const _NodePanel({required this.child, required this.borderColor});

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _NodeColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

IconData _iconForAccount(String type) => switch (type) {
  'bank' => Icons.account_balance_outlined,
  'cash' => Icons.payments_outlined,
  'credit' => Icons.credit_card_outlined,
  'trading' => Icons.show_chart_rounded,
  _ => Icons.account_balance_wallet_outlined,
};
