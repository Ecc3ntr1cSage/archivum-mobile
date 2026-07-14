import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
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
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late final PrayerRepository _repo;
  late int _selectedYear;
  late int _selectedMonth;

  List<PrayerDay> _monthPrayers = [];
  bool _loading = true;

  int get _startYear => widget.startYear;
  int get _startMonth => widget.startMonth;

  @override
  void initState() {
    super.initState();
    _repo = PrayerRepository(Supabase.instance.client);
    final now = DateTime.now();
    _selectedYear = now.year < widget.startYear ? widget.startYear : now.year;
    _selectedMonth =
        (_selectedYear == widget.startYear && now.month < widget.startMonth)
        ? widget.startMonth
        : now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final monthPrayers = await _repo.fetchPrayersForMonth(
        _selectedYear,
        _selectedMonth,
      );
      if (!mounted) return;
      setState(() => _monthPrayers = monthPrayers);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load history: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> _availableYears() {
    final currentYear = DateTime.now().year;
    final end = currentYear < _startYear ? _startYear : currentYear;
    return List.generate(end - _startYear + 1, (i) => _startYear + i);
  }

  List<int> _availableMonths() {
    final now = DateTime.now();
    final startMonth = _selectedYear == _startYear ? _startMonth : 1;
    final endMonth = _selectedYear == now.year ? now.month : 12;
    return List.generate(endMonth - startMonth + 1, (i) => startMonth + i);
  }

  void _onYearChanged(int year) {
    final now = DateTime.now();
    var month = _selectedMonth;

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

  int _intensityForDay(int day) {
    final target = DateTime(_selectedYear, _selectedMonth, day);
    for (final prayer in _monthPrayers) {
      if (prayer.date.year == target.year &&
          prayer.date.month == target.month &&
          prayer.date.day == target.day) {
        return prayer.completedCount;
      }
    }
    return -1;
  }

  Color _intensityColor(ArchivumTheme theme, int intensity) {
    switch (intensity) {
      case 5:
        return theme.primary;
      case 4:
        return theme.primary.withValues(alpha: 0.78);
      case 3:
        return theme.secondary;
      case 2:
        return theme.chart3;
      case 1:
        return theme.destructive.withValues(alpha: 0.72);
      case 0:
        return theme.mutedForeground.withValues(alpha: 0.18);
      default:
        return theme.muted;
    }
  }

  int get _totalPrayers =>
      _monthPrayers.fold(0, (sum, day) => sum + day.completedCount);

  int get _perfectDays =>
      _monthPrayers.where((day) => day.completedCount == 5).length;

  double get _averageDaily {
    if (_monthPrayers.isEmpty) return 0;
    return _totalPrayers / _monthPrayers.length;
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
            _HistoryHeader(title: widget.title),
            Expanded(
              child: _loading
                  ? const _HistoryLoading()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: theme.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          _HistoryFilters(
                            selectedMonth: _selectedMonth,
                            selectedYear: _selectedYear,
                            months: _availableMonths(),
                            years: _availableYears(),
                            monthNames: _monthNames,
                            onMonthChanged: _onMonthChanged,
                            onYearChanged: _onYearChanged,
                          ),
                          const SizedBox(height: 14),
                          _HistorySummary(
                            totalPrayers: _totalPrayers,
                            perfectDays: _perfectDays,
                            averageDaily: _averageDaily,
                          ),
                          const SizedBox(height: 14),
                          _HeatmapPanel(
                            selectedMonth: _selectedMonth,
                            selectedYear: _selectedYear,
                            intensityForDay: _intensityForDay,
                            intensityColor: (intensity) =>
                                _intensityColor(theme, intensity),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: theme.card,
              foregroundColor: theme.foreground,
              side: BorderSide(color: theme.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Monthly consistency and completion patterns.',
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

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.selectedMonth,
    required this.selectedYear,
    required this.months,
    required this.years,
    required this.monthNames,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final int selectedMonth;
  final int selectedYear;
  final List<int> months;
  final List<int> years;
  final List<String> monthNames;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _FilterDropdown(
            value: selectedMonth,
            items: months,
            label: (month) => monthNames[month - 1],
            onChanged: onMonthChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _FilterDropdown(
            value: selectedYear,
            items: years,
            label: (year) => year.toString(),
            onChanged: onYearChanged,
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  final int value;
  final List<int> items;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: theme.input.withValues(alpha: 0.45),
      ),
      dropdownColor: theme.popover,
      icon: Icon(Icons.expand_more_rounded, color: theme.mutedForeground),
      style: TextStyle(
        color: theme.foreground,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<int>(value: item, child: Text(label(item))),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.totalPrayers,
    required this.perfectDays,
    required this.averageDaily,
  });

  final int totalPrayers;
  final int perfectDays;
  final double averageDaily;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Prayers',
            value: totalPrayers.toString(),
            icon: Icons.done_all_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Perfect',
            value: perfectDays.toString(),
            icon: Icons.verified_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Average',
            value: averageDaily.toStringAsFixed(1),
            icon: Icons.insights_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: theme.mutedForeground, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HeatmapPanel extends StatelessWidget {
  const _HeatmapPanel({
    required this.selectedMonth,
    required this.selectedYear,
    required this.intensityForDay,
    required this.intensityColor,
  });

  final int selectedMonth;
  final int selectedYear;
  final int Function(int day) intensityForDay;
  final Color Function(int intensity) intensityColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final firstWeekday = DateTime(selectedYear, selectedMonth, 1).weekday;
    final startOffset = firstWeekday % 7;
    final totalCells = startOffset + daysInMonth;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: theme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Monthly heatmap',
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: theme.mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();

              final day = index - startOffset + 1;
              final intensity = intensityForDay(day);
              final color = intensityColor(intensity);

              return Tooltip(
                message: intensity < 0
                    ? 'Day $day, no record'
                    : 'Day $day, $intensity of 5',
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: intensity < 0
                          ? theme.border
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: intensity > 0
                            ? Colors.white
                            : theme.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: theme.border, height: 1),
          const SizedBox(height: 12),
          _Legend(theme: theme, intensityColor: intensityColor),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.theme, required this.intensityColor});

  final ArchivumTheme theme;
  final Color Function(int intensity) intensityColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Intensity',
          style: TextStyle(
            color: theme.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        for (final intensity in [-1, 0, 1, 2, 3, 4, 5])
          Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              color: intensityColor(intensity),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.border),
            ),
          ),
      ],
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Center(
      child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2),
    );
  }
}
