import 'package:flutter/material.dart';

class SolatHistoryPage extends StatelessWidget {
  const SolatHistoryPage({super.key});

  static const Color _primary = Color(0xFF8A2CE2);
  
  // Tailwind colors mapped
  static const Color _prayer1 = Color(0xFF991B1B);
  static const Color _prayer2 = Color(0xFFEA580C);
  static const Color _prayer3 = Color(0xFFF59E0B);
  static const Color _prayer4 = Color(0xFF65A30D);
  static const Color _prayer5 = Color(0xFF22C55E);

  Color _getPrayerColor(int intensity, bool isDark) {
    switch (intensity) {
      case 1:
        return _prayer1;
      case 2:
        return _prayer2;
      case 3:
        return _prayer3;
      case 4:
        return _prayer4;
      case 5:
        return _prayer5;
      case 0:
      default:
        return isDark ? const Color(0xFF2D2438) : const Color(0xFFE2E8F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF191121) : const Color(0xFFF7F6F8);
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
          "Faith History",
          style: TextStyle(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: onSurface,
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMonthFilters(context),
            const SizedBox(height: 8),
            _buildHeatmapSection(context, isDark, onSurface),
            _buildStatsSection(context, isDark, onSurface),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildMonthChip("October 2023", isActive: true, isDark: isDark),
          const SizedBox(width: 12),
          _buildMonthChip("September 2023", isActive: false, isDark: isDark),
          const SizedBox(width: 12),
          _buildMonthChip("August 2023", isActive: false, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildMonthChip(String text, {required bool isActive, required bool isDark}) {
    final bgColor = isActive
        ? _primary
        : (isDark ? _primary.withValues(alpha: 0.1) : const Color(0xFFE2E8F0));
    final textColor = isActive
        ? Colors.white
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155));

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.expand_more,
            color: textColor,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection(BuildContext context, bool isDark, Color onSurface) {
    final cardBg = isDark ? _primary.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? _primary.withValues(alpha: 0.1) : const Color(0xFFE2E8F0);
    final mutedText = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final List<int> intensities = [
      3, 5, 4, 2, 1, 0, 5, // W1
      5, 5, 4, 3, 2, 4, 5, // W2
      0, 1, 5, 5, 4, 5, 5, // W3
      3, 4, 5, 5, 5, 4, 3, // W4
      5, 5, 2              // W5
    ];

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
              const Icon(Icons.analytics, color: _primary),
              const SizedBox(width: 8),
              Text(
                "Prayer Consistency",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
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
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              final intensity = index < intensities.length ? intensities[index] : 0;
              return Container(
                decoration: BoxDecoration(
                  color: _getPrayerColor(intensity, isDark),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PRAYER INTENSITY",
                style: TextStyle(
                  fontSize: 10,
                  color: mutedText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: List.generate(6, (index) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: _getPrayerColor(index, isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Less", style: TextStyle(fontSize: 9, color: mutedText)),
              const SizedBox(width: 38), // Roughly spacing for scale
              Text("More", style: TextStyle(fontSize: 9, color: mutedText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildStatCard(
            context,
            isDark: isDark,
            onSurface: onSurface,
            icon: Icons.done_all,
            label: "Total Completed",
            value: "124 Prayers",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                const Text(
                  "+12%",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            isDark: isDark,
            onSurface: onSurface,
            icon: Icons.query_stats,
            label: "Average Daily",
            value: "4.1 / 5",
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            isDark: isDark,
            onSurface: onSurface,
            icon: Icons.local_fire_department,
            label: "Longest Streak",
            value: "18 Days",
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "CURRENT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
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
    final cardBg = isDark ? _primary.withValues(alpha: 0.1) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? _primary.withValues(alpha: 0.2) : const Color(0xFFE2E8F0);
    final mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
