import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/prayer_repository.dart';
import '../domain/prayer_day.dart';

class PrayerHistoryPage extends StatefulWidget {
  const PrayerHistoryPage({
    super.key,
    this.title = 'Prayer History',
    this.primaryColor,
    this.startYear = 2026,
    this.startMonth = 1,
  });

  final String title;
  final Color? primaryColor;
  final int startYear;
  final int startMonth;

  @override
  State<PrayerHistoryPage> createState() => _PrayerHistoryPageState();
}

class _PrayerHistoryPageState extends State<PrayerHistoryPage> {
  late final PrayerRepository _repo;
  late int _selectedYear;
  late int _selectedMonth;

  List<PrayerDay> _monthPrayers = [];
  int _totalCompleted = 0;
  int _totalDays = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = PrayerRepository(Supabase.instance.client);
    final now = DateTime.now();
    _selectedYear = now.year < widget.startYear ? widget.startYear : now.year;
    _selectedMonth = (_selectedYear == widget.startYear && now.month < widget.startMonth)
        ? widget.startMonth
        : now.month;
    _loadData();
  }

  Color get _primary => widget.primaryColor ?? const Color(0xFF8A2CE2);
  int get _startYear => widget.startYear;
  int get _startMonth => widget.startMonth;

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final monthPrayers =
          await _repo.fetchPrayersForMonth(_selectedYear, _selectedMonth);
      final stats = await _repo.fetchAllTimeStats();
      if (mounted) {
        setState(() {
          _monthPrayers = monthPrayers;
          _totalCompleted = stats.$1;
          _totalDays = stats.$2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Available years/months ──────────────────────────────────────────────

  List<int> _availableYears() {
    final currentYear = DateTime.now().year;
    final end = currentYear < _startYear ? _startYear : currentYear;
    return List.generate(end - _startYear + 1, (i) => _startYear + i);
  }

  List<int> _availableMonths() {
    final now = DateTime.now();
    final startM =
        _selectedYear == _startYear ? _startMonth : 1;
    final endM =
        _selectedYear == now.year ? now.month : 12;
    return List.generate(endM - startM + 1, (i) => startM + i);
  }

  void _onYearChanged(int year) {
    final now = DateTime.now();
    int month = _selectedMonth;
    if (year == _startYear && month < _startMonth) month = _startMonth;
    if (year == now.year && month > now.month) month = now.month;
    setState(() {
      _selectedYear = year;
      _selectedMonth = month;
    });
    _loadData();
  }

  void _onMonthChanged(int month) {
    setState(() => _selectedMonth = month);
    _loadData();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  int _intensityForDay(int day) {
    final target = DateTime(_selectedYear, _selectedMonth, day);
    for (final p in _monthPrayers) {
      if (p.date.year == target.year &&
          p.date.month == target.month &&
          p.date.day == target.day) {
        return p.completedCount;
      }
    }
    return -1; // no record
  }

  Color _intensityColor(int intensity, bool isDark) {
    switch (intensity) {
      case 1:
        return const Color(0xFFDC2626); // red
      case 2:
        return const Color(0xFFEA580C); // orange
      case 3:
        return const Color(0xFFF59E0B); // yellow
      case 4:
        return const Color(0xFF0D9488); // teal
      case 5:
        return const Color(0xFF22C55E); // green
      case 0:
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
      default: // -1 = no record
        return isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    }
  }

  String get _averageDaily {
    if (_totalDays == 0) return '—';
    return (_totalCompleted / _totalDays).toStringAsFixed(1);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildFilters(context, isDark, onSurface),
                  const SizedBox(height: 8),
                  _buildHeatmap(context, isDark, onSurface),
                  const SizedBox(height: 8),
                  _buildStats(context, isDark, onSurface),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  Widget _buildFilters(
      BuildContext context, bool isDark, Color onSurface) {
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final bgColor =
        isDark ? const Color(0xFF1E293B) : Colors.white;

    DropdownButtonFormField<int> styledDropdown({
      required int value,
      required List<int> items,
      required String Function(int) label,
      required ValueChanged<int?> onChanged,
    }) {
      return DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: bgColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primary),
          ),
        ),
        dropdownColor: bgColor,
        style: TextStyle(
            color: onSurface, fontSize: 14, fontWeight: FontWeight.w600),
        icon: Icon(Icons.expand_more, color: onSurface, size: 20),
        items: items
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(label(v)),
                ))
            .toList(),
        onChanged: onChanged,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: styledDropdown(
              value: _selectedMonth,
              items: _availableMonths(),
              label: (m) => _monthNames[m - 1],
              onChanged: (v) => v != null ? _onMonthChanged(v) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: styledDropdown(
              value: _selectedYear,
              items: _availableYears(),
              label: (y) => y.toString(),
              onChanged: (v) => v != null ? _onYearChanged(v) : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar heatmap ─────────────────────────────────────────────────────

  Widget _buildHeatmap(
      BuildContext context, bool isDark, Color onSurface) {
    final cardBg = isDark
        ? _primary.withValues(alpha: 0.05)
        : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? _primary.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);
    final mutedText =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    // weekday: Mon=1..Sun=7  →  offset for S M T W T F S layout: Sun=0
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    final startOffset = firstWeekday % 7; // Mon=1→1, Sun=7→0
    final totalCells = startOffset + daysInMonth;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: _primary),
              const SizedBox(width: 8),
              Text(
                'Prayer Consistency',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day-of-week labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: mutedText,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }
              final day = index - startOffset + 1;
              final intensity = _intensityForDay(day);
              final color = _intensityColor(intensity, isDark);
              return Tooltip(
                message: intensity < 0
                    ? 'Day $day — no record'
                    : 'Day $day — $intensity/5',
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 9,
                        color: intensity > 0
                          ? Colors.white.withValues(alpha: 0.85)
                          : mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRAYER INTENSITY',
                style: TextStyle(
                  fontSize: 10,
                  color: mutedText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  // no record
                  _legendDot(
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  // 0 prayed
                  _legendDot(
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  _legendDot(const Color(0xFFDC2626)),
                  _legendDot(const Color(0xFFEA580C)),
                  _legendDot(const Color(0xFFF59E0B)),
                  _legendDot(const Color(0xFF0D9488)),
                  _legendDot(const Color(0xFF22C55E)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('None→0→1→2→3→4→5',
                  style: TextStyle(fontSize: 9, color: mutedText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // ── Stats ────────────────────────────────────────────────────────────────

  Widget _buildStats(
      BuildContext context, bool isDark, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildStatCard(
            context,
            isDark: isDark,
            onSurface: onSurface,
            icon: Icons.done_all,
            label: 'Total Completed (all time)',
            value: '$_totalCompleted Prayers',
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            isDark: isDark,
            onSurface: onSurface,
            icon: Icons.query_stats,
            label: 'Average Daily (all time)',
            value: '$_averageDaily / 5',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required bool isDark,
    required Color onSurface,
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    final cardBg = isDark
        ? _primary.withValues(alpha: 0.1)
        : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? _primary.withValues(alpha: 0.2)
        : const Color(0xFFE2E8F0);
    final mutedText =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
