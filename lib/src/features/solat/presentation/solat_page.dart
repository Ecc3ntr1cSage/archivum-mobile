import 'package:flutter/material.dart';

class SolatPage extends StatefulWidget {
  const SolatPage({super.key});

  @override
  State<SolatPage> createState() => _SolatPageState();
}

class _SolatPageState extends State<SolatPage> {
  static const Color _primary = Color(0xFF8A2CE2);
  static const Color _secondary = Color(0xFFFF8C00);

  final Map<String, bool> _prayers = {
    'Fajr': true,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': false,
  };

  final Map<String, String> _prayerTimes = {
    'Fajr': '05:42 AM',
    'Dhuhr': '12:58 PM',
    'Asr': '04:15 PM',
    'Maghrib': '07:02 PM',
    'Isha': '08:14 PM',
  };

  final Map<String, IconData> _prayerIcons = {
    'Fajr': Icons.wb_twilight_outlined,
    'Dhuhr': Icons.light_mode_outlined,
    'Asr': Icons.wb_sunny_outlined,
    'Maghrib': Icons.wb_twilight_outlined,
    'Isha': Icons.dark_mode_outlined,
  };

  void togglePrayer(String name) {
    setState(() {
      _prayers[name] = !(_prayers[name] ?? false);
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF080808) : const Color(0xFFF6F6F8);
    final completed = _prayers.values.where((v) => v).length;
    final total = _prayers.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildProgressOverview(context, completed, total, progress),
              const SizedBox(height: 16),
              _buildGoalVisualization(context, progress),
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
    final onSurfaceDisabled = isDark
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
            child: Icon(
              Icons.calendar_month_outlined,
              color: _primary,
              size: 30,
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
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    color: onSurfaceDisabled,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildProgressOverview(
    BuildContext context,
    int completed,
    int total,
    double progress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "DAILY STREAK",
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "12",
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Days",
                        style: TextStyle(
                          color: onSurfaceMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: _secondary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Personal Best",
                        style: TextStyle(
                          color: _secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "COMPLETED",
                    style: TextStyle(
                      color: onSurfaceMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "$completed/$total",
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Solat",
                        style: TextStyle(
                          color: onSurfaceMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _secondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalVisualization(BuildContext context, double progress) {
    final completedCount = _prayers.values.where((v) => v).length;
    final isAlmostThere = completedCount == _prayers.length - 1;
    final nextPrayer =
        _prayers.entries.where((e) => !e.value).firstOrNull?.key ?? "Solat";
    final message = isAlmostThere
        ? "Almost there! Just $nextPrayer left to complete your day."
        : completedCount == _prayers.length
        ? "Masha'Allah! You have completed all prayers for today."
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
                          style: TextStyle(
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
                onTap: () {},
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
          ..._prayers.entries.map((entry) {
            final name = entry.key;
            final completed = entry.value;
            final time = _prayerTimes[name]!;
            final icon = _prayerIcons[name]!;

            if (completed) {
              return Column(
                children: [
                  _buildPrayerItem(context, name, time, icon, completed),
                  const SizedBox(height: 12),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildUpcomingPrayerItem(context, name, time, icon),
                  const SizedBox(height: 12),
                ],
              );
            }
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(
    BuildContext context,
    String name,
    String time,
    IconData icon,
    bool completed,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: () => togglePrayer(name),
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
                    "$time • Completed",
                    style: TextStyle(color: onSurfaceMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: onSurface, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingPrayerItem(
    BuildContext context,
    String name,
    String time,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => togglePrayer(name),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$time • Upcoming",
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
