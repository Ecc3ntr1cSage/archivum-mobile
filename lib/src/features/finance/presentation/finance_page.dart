import 'package:flutter/material.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<Map<String, String>> _income = [];
  final List<Map<String, String>> _expense = [];

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _details = TextEditingController();

  static const Color _incomeColor = Color(0xFF8A2CE2);
  static const Color _expenseColor = Color(0xFFFF8C00);

  String? _selectedTag;

  final List<String> _incomeTags = ['Salary', 'Gift', 'Interest', 'Other'];
  final List<String> _expenseTags = ['Food', 'Transport', 'Bills', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTag = null;
          _amount.clear();
          _details.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amount.dispose();
    _details.dispose();
    super.dispose();
  }

  void _save(bool isIncome) {
    final a = _amount.text.trim();
    final d = _details.text.trim();
    final t = _selectedTag ?? 'Other';
    if (a.isEmpty) return;
    final item = {'amount': a, 'details': d, 'tag': t};
    setState(() {
      if (isIncome) {
        _income.insert(0, item);
      } else {
        _expense.insert(0, item);
      }
      _amount.clear();
      _details.clear();
      _selectedTag = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${isIncome ? 'Income' : 'Expense'} logged successfully!',
        ),
        backgroundColor: isIncome ? _incomeColor : _expenseColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurfaceMuted),
        title: Text(
          "Financial Logger",
          style: TextStyle(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: _tabController.index == 0
                  ? _expenseColor
                  : _incomeColor,
              indicatorWeight: 2,
              labelColor: _tabController.index == 0
                  ? _expenseColor
                  : _incomeColor,
              unselectedLabelColor: onSurfaceMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
              ],
              onTap: (index) {
                setState(() {}); // Rebuild to update tab colors
              },
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionTab(
            context: context,
            isIncome: false,
            title: "Add Expense",
            subtitle: "Log your outgoings and bills",
            color: _expenseColor,
            icon: Icons.remove_circle,
            inputIcon: Icons.shopping_cart,
            tags: _expenseTags,
          ),
          _buildTransactionTab(
            context: context,
            isIncome: true,
            title: "Add Income",
            subtitle: "Log your earnings and windfalls",
            color: _incomeColor,
            icon: Icons.add_circle,
            inputIcon: Icons.payments,
            tags: _incomeTags,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTab({
    required BuildContext context,
    required bool isIncome,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required IconData inputIcon,
    required List<String> tags,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0B0D14) : const Color(0xFFF1F5F9);
    final inputBorder = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFCBD5E1);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: onSurfaceMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Amount Input
            Text(
              "Amount",
              style: TextStyle(
                color: onSurfaceMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: onSurfaceMuted.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(inputIcon, color: color),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Input
            Text(
              "Details",
              style: TextStyle(
                color: onSurfaceMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _details,
              style: TextStyle(
                color: onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: isIncome
                    ? "e.g. Monthly Salary, Freelance project"
                    : "e.g. Groceries, Electricity",
                hintStyle: TextStyle(
                  color: onSurfaceMuted.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.description, color: onSurfaceMuted),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Tag
            Text(
              "Category Tag",
              style: TextStyle(
                color: onSurfaceMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...tags.map((tag) {
                  final isSelected = _selectedTag == tag;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTag = tag;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.3)
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? color : onSurfaceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.add, color: color, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Log Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _save(isIncome),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: color.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Text(
                      isIncome ? "Log Income" : "Log Expense",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // View History
            Center(
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View Financial History",
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: color, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
