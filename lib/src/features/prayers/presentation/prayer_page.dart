import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/prayer_repository.dart';
import '../domain/prayer_day.dart';
import 'prayer_history_page.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  static const Color _primary = Color(0xFF8A2CE2);
  static const Color _secondary = Color(0xFFFF8C00);

  static const List<String> _prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  static const Map<String, IconData> _prayerIcons = {
    'Fajr': Icons.wb_twilight_outlined,
    'Dhuhr': Icons.light_mode_outlined,
    'Asr': Icons.wb_sunny_outlined,
    'Maghrib': Icons.wb_twilight_outlined,
    'Isha': Icons.dark_mode_outlined,
  };

  late final PrayerRepository _repo;
  late final DateTime _activeDate;

  PrayerDay? _prayerDay;
  bool _loading = true;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _repo = PrayerRepository(Supabase.instance.client);
    _activeDate = getActiveDate();
    _loadPrayerDay();
  }

  Future<void> _loadPrayerDay() async {
    setState(() => _loading = true);
    try {
      final day = await _repo.fetchOrCreatePrayerDay(_activeDate);
      if (mounted) setState(() => _prayerDay = day);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load prayers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePrayer(String name) async {
    if (_prayerDay == null || _toggling) return;
    final currentValue = _prayerDay!.prayerValue(name);
    final newValue = !currentValue;

    // Optimistic update
    setState(() {
      _prayerDay = _prayerDay!.copyWithPrayer(name, newValue);
      _toggling = true;
    });

    try {
      final updated =
          await _repo.updatePrayer(_prayerDay!.id!, name, newValue);
      if (mounted) setState(() => _prayerDay = updated);
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() => _prayerDay = _prayerDay!.copyWithPrayer(name, currentValue));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update prayer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  /// Format: "Logging prayer for 01/03 (Sunday)"
  String _getLoggingLabel() {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final d = _activeDate;
    final day = weekdays[d.weekday - 1];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return 'Logging prayer for $dd/$mm ($day)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080808) : const Color(0xFFF6F6F8);
    final completed = _prayerDay?.completedCount ?? 0;
    final progress = _prayerDay?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildGoalVisualization(context, completed, progress),
                    const SizedBox(height: 16),
                    _buildSchedule(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: _primary,
                size: 30,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrayerHistoryPage(),
                  ),
                );
              },
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "Daily Prayers",
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getLoggingLabel(),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'reset at 5am',
                  style: TextStyle(
                    color: onSurfaceMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalVisualization(
      BuildContext context, int completedCount, double progress) {
    final nextPrayer = _prayerNames
        .where((n) => !(_prayerDay?.prayerValue(n) ?? false))
        .firstOrNull;
    final isAlmostThere = completedCount == _prayerNames.length - 1;
    final message = completedCount == _prayerNames.length
        ? "Masha'Allah! You have completed all prayers for today."
        : isAlmostThere && nextPrayer != null
            ? "Almost there! Just $nextPrayer left to complete your day."
            : "Keep going! Complete your prayers for today.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white.withValues(alpha: 0.1),
                size: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daily Progress",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${(progress * 100).toInt()}% Done",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (int i = 0; i < 5; i++) ...[
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: i < completedCount
                                  ? _primary
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        if (i < 4) const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedule(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Schedule",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrayerHistoryPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        "View History",
                        style: TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.history, color: _primary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._prayerNames.map((name) {
            final done = _prayerDay?.prayerValue(name) ?? false;
            final icon = _prayerIcons[name]!;
            return Column(
              children: [
                done
                    ? _buildCompletedPrayerItem(context, name, icon)
                    : _buildUpcomingPrayerItem(context, name, icon),
                const SizedBox(height: 12),
              ],
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompletedPrayerItem(
      BuildContext context, String name, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: _toggling ? null : () => _togglePrayer(name),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Completed • tap to undo",
                    style: TextStyle(color: onSurfaceMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: _primary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingPrayerItem(
      BuildContext context, String name, IconData icon) {
    return InkWell(
      onTap: _toggling ? null : () => _togglePrayer(name),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.2),
              spreadRadius: 4,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Not prayed yet • tap to mark",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
