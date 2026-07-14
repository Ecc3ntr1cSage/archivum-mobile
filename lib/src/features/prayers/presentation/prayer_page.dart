import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/prayer_repository.dart';
import '../domain/prayer_day.dart';
import 'prayer_history_page.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load prayers: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePrayer(String name) async {
    if (_prayerDay == null || _toggling) return;

    final currentValue = _prayerDay!.prayerValue(name);
    final newValue = !currentValue;

    setState(() {
      _prayerDay = _prayerDay!.copyWithPrayer(name, newValue);
      _toggling = true;
    });

    try {
      final updated = await _repo.updatePrayer(_prayerDay!.id!, name, newValue);
      if (mounted) setState(() => _prayerDay = updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _prayerDay = _prayerDay!.copyWithPrayer(name, currentValue);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update prayer: $error')),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  String _getLoggingLabel() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final day = weekdays[_activeDate.weekday - 1];
    final dd = _activeDate.day.toString().padLeft(2, '0');
    final mm = _activeDate.month.toString().padLeft(2, '0');
    return '$dd/$mm, $day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final completed = _prayerDay?.completedCount ?? 0;
    final progress = _prayerDay?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const _PrayerLoading()
            : RefreshIndicator(
                onRefresh: _loadPrayerDay,
                color: theme.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  children: [
                    _PrayerHeader(
                      dateLabel: _getLoggingLabel(),
                      onHistoryTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrayerHistoryPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _ProgressPanel(
                      completed: completed,
                      progress: progress,
                      nextPrayer: _nextPrayer,
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(
                      title: "Today's prayers",
                      trailing: '$completed of ${_prayerNames.length}',
                    ),
                    const SizedBox(height: 10),
                    for (final name in _prayerNames) ...[
                      _PrayerRow(
                        name: name,
                        icon: _prayerIcons[name]!,
                        isDone: _prayerDay?.prayerValue(name) ?? false,
                        isBusy: _toggling,
                        onTap: () => _togglePrayer(name),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String? get _nextPrayer {
    for (final prayer in _prayerNames) {
      if (!(_prayerDay?.prayerValue(prayer) ?? false)) return prayer;
    }
    return null;
  }
}

class _PrayerHeader extends StatelessWidget {
  const _PrayerHeader({required this.dateLabel, required this.onHistoryTap});

  final String dateLabel;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.mosque_outlined, color: theme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prayers',
                style: TextStyle(
                  color: theme.foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: TextStyle(color: theme.mutedForeground, fontSize: 12),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Prayer history',
          child: IconButton(
            onPressed: onHistoryTap,
            style: IconButton.styleFrom(
              backgroundColor: theme.card,
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.border),
            ),
            icon: const Icon(Icons.history_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.completed,
    required this.progress,
    required this.nextPrayer,
  });

  final int completed;
  final double progress;
  final String? nextPrayer;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;
    final isComplete = completed == 5;
    final message = isComplete
        ? "Masha'Allah, all prayers are complete for today."
        : nextPrayer == null
        ? 'Keep your day steady.'
        : '$nextPrayer is next in your daily rhythm.';

    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily progress',
                      style: TextStyle(
                        color: theme.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed / 5 complete',
                      style: TextStyle(
                        color: theme.foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _ProgressRing(progress: progress),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: theme.mutedForeground,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              final done = index < completed;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 8,
                  margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: done
                        ? theme.primary
                        : theme.mutedForeground.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: theme.mutedForeground.withValues(alpha: 0.14),
            color: theme.primary,
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: theme.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.foreground,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            trailing,
            style: TextStyle(
              color: theme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.icon,
    required this.isDone,
    required this.isBusy,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool isDone;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone ? theme.primary.withValues(alpha: 0.12) : theme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone ? theme.primary.withValues(alpha: 0.4) : theme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDone
                    ? theme.primary.withValues(alpha: 0.16)
                    : theme.muted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDone ? theme.primary : theme.mutedForeground,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: theme.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isDone ? 'Completed, tap to undo' : 'Pending, tap to mark',
                    style: TextStyle(
                      color: theme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isDone ? Icons.check_circle_rounded : Icons.add_circle_outline,
                key: ValueKey(isDone),
                color: isDone ? theme.primary : theme.mutedForeground,
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerLoading extends StatelessWidget {
  const _PrayerLoading();

  @override
  Widget build(BuildContext context) {
    final theme = context.archivumTheme;

    return Center(
      child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2),
    );
  }
}
