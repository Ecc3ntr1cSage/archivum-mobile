import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../domain/transaction.dart';
import '../data/transaction_repository.dart';

class FinancialHistoryPage extends StatefulWidget {
  const FinancialHistoryPage({super.key});

  @override
  State<FinancialHistoryPage> createState() => _FinancialHistoryPageState();
}

class _FinancialHistoryPageState extends State<FinancialHistoryPage> {
  final TransactionRepository _repository = TransactionRepository(Supabase.instance.client);
  
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  
  String _selectedMonth = 'All';
  String _selectedType = 'All';
  String _selectedCategory = 'All';
  
  List<String> _months = ['All'];
  List<String> _categories = ['All'];
  
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _repository.getTransactions();
      
      final monthsSet = <String>{};
      final categoriesSet = <String>{};
      
      double income = 0;
      double expense = 0;
      
      for (var t in transactions) {
        final monthKey = DateFormat('MMM yyyy').format(t.createdAt);
        monthsSet.add(monthKey);
        categoriesSet.add(t.tag);
        
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
      
      if (mounted) {
        setState(() {
          _allTransactions = transactions;
          _filteredTransactions = transactions;
          
          _months = ['All', ...monthsSet.toList()..sort((a, b) {
            final dateA = DateFormat('MMM yyyy').parse(a);
            final dateB = DateFormat('MMM yyyy').parse(b);
            return dateB.compareTo(dateA); // Newest first
          })];
          
          _categories = ['All', ...categoriesSet.toList()..sort()];
          
          _totalIncome = income;
          _totalExpense = expense;
          _currentBalance = income - expense;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load transactions: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((t) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            t.details.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.tag.toLowerCase().contains(_searchQuery.toLowerCase());
            
        // Month filter
        final monthKey = DateFormat('MMM yyyy').format(t.createdAt);
        final matchesMonth = _selectedMonth == 'All' || monthKey == _selectedMonth;
        
        // Type filter
        final matchesType = _selectedType == 'All' ||
            (_selectedType == 'Income' && t.type == TransactionType.income) ||
            (_selectedType == 'Expense' && t.type == TransactionType.expense);
            
        // Category filter
        final matchesCategory = _selectedCategory == 'All' || t.tag == _selectedCategory;
        
        return matchesSearch && matchesMonth && matchesType && matchesCategory;
      }).toList();
      
      // Update totals based on filtered results
      _totalIncome = 0;
      _totalExpense = 0;
      for (var t in _filteredTransactions) {
        if (t.type == TransactionType.income) {
          _totalIncome += t.amount;
        } else {
          _totalExpense += t.amount;
        }
      }
      _currentBalance = _totalIncome - _totalExpense;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Financial History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Top Section (Summary)
              Container(
                padding: const EdgeInsets.all(16),
                color: surfaceColor,
                child: Column(
                  children: [
                    // Balance overview card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_currentBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Two small cards: Total Income and Total Expenses
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Income',
                            amount: _totalIncome,
                            icon: Icons.arrow_downward,
                            color: const Color(0xFF10B981), // Green
                            bgColor: surfaceColor,
                            borderColor: borderColor,
                            textColor: onSurface,
                            mutedColor: onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Expense',
                            amount: _totalExpense,
                            icon: Icons.arrow_upward,
                            color: const Color(0xFFEF4444), // Red
                            bgColor: surfaceColor,
                            borderColor: borderColor,
                            textColor: onSurface,
                            mutedColor: onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Filters/Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: surfaceColor,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search details or tags...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Dropdowns
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDropdown(
                            value: _selectedMonth,
                            items: _months,
                            onChanged: (val) {
                              if (val != null) {
                                _selectedMonth = val;
                                _applyFilters();
                              }
                            },
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(width: 8),
                         _buildDropdown(
                            value: _selectedType,
                            items: ['All', 'Income', 'Expense'],
                            onChanged: (val) {
                              if (val != null) {
                                _selectedType = val;
                                _applyFilters();
                              }
                            },
                            icon: Icons.account_balance_wallet,
                          ),
                          const SizedBox(width: 8),
                          _buildDropdown(
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (val) {
                              if (val != null) {
                                _selectedCategory = val;
                                _applyFilters();
                              }
                            },
                            icon: Icons.category,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Section (Transaction List)
              Expanded(
                child: _filteredTransactions.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions found',
                          style: TextStyle(color: onSurfaceMuted, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTransactions.length,
                        separatorBuilder: (context, index) => Divider(color: borderColor, height: 24),
                        itemBuilder: (context, index) {
                          final t = _filteredTransactions[index];
                          final isIncome = t.type == TransactionType.income;
                          final amountColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                          final prefix = isIncome ? '+' : '-';
                          
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon container
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: amountColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncome ? Icons.south_west : Icons.north_east,
                                  color: amountColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Date (small, muted)
                                        Text(
                                          DateFormat('MMM dd, yyyy • hh:mm a').format(t.createdAt),
                                          style: TextStyle(
                                            color: onSurfaceMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        
                                        // Amount (aligned right, green/red)
                                        Text(
                                          '$prefix\$${t.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: amountColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Details (bold, primary text)
                                    Text(
                                      t.details,
                                      style: TextStyle(
                                        color: onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Tags
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t.tag,
                                        style: TextStyle(
                                          color: onSurfaceMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: value,
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            isDense: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}