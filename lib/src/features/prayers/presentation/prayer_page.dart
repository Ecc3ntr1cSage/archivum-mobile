import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../data/prayer_repository.dart';
import '../domain/prayer_day.dart';
import 'prayer_history_page.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  static const List<_PrayerMeta> _prayers = [
    _PrayerMeta('Fajr', '05:12 AM', Icons.wb_twilight_outlined),
    _PrayerMeta('Dhuhr', '12:34 PM', Icons.light_mode_outlined),
    _PrayerMeta('Asr', '03:58 PM', Icons.wb_sunny_outlined),
    _PrayerMeta('Maghrib', '06:21 PM', Icons.nights_stay_outlined),
    _PrayerMeta('Isha', '07:45 PM', Icons.bedtime_outlined),
  ];

  late final PrayerRepository _repo;
  late final DateTime _activeDate;

  PrayerDay? _prayerDay;
  List<PrayerDay> _historyDays = [];
  bool _loading = true;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _repo = PrayerRepository(Supabase.instance.client);
    _activeDate = getActiveDate();
    _loadPrayerData();
  }

  Future<void> _loadPrayerData() async {
    setState(() => _loading = true);
    try {
      final day = await _repo.fetchOrCreatePrayerDay(_activeDate);
      final history = await _fetchHistoryPreview();
      if (!mounted) return;
      setState(() {
        _prayerDay = day;
        _historyDays = history;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load prayers: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<PrayerDay>> _fetchHistoryPreview() async {
    final firstDate = _activeDate.subtract(const Duration(days: 27));
    final months = <DateTime>[
      DateTime(_activeDate.year, _activeDate.month),
      if (firstDate.year != _activeDate.year ||
          firstDate.month != _activeDate.month)
        DateTime(firstDate.year, firstDate.month),
    ];

    final days = <PrayerDay>[];
    for (final month in months) {
      days.addAll(await _repo.fetchPrayersForMonth(month.year, month.month));
    }
    return days;
  }

  Future<void> _togglePrayer(String name) async {
    if (_prayerDay == null || _toggling) return;

    final currentValue = _prayerDay!.prayerValue(name);
    final newValue = !currentValue;
    final optimistic = _prayerDay!.copyWithPrayer(name, newValue);

    setState(() {
      _prayerDay = optimistic;
      _historyDays = _replaceHistoryDay(_historyDays, optimistic);
      _toggling = true;
    });

    try {
      final updated = await _repo.updatePrayer(_prayerDay!.id!, name, newValue);
      if (!mounted) return;
      setState(() {
        _prayerDay = updated;
        _historyDays = _replaceHistoryDay(_historyDays, updated);
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      final reverted = _prayerDay!.copyWithPrayer(name, currentValue);
      setState(() {
        _prayerDay = reverted;
        _historyDays = _replaceHistoryDay(_historyDays, reverted);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update prayer: ${AppError.from(error, stackTrace).message}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  List<PrayerDay> _replaceHistoryDay(List<PrayerDay> days, PrayerDay updated) {
    var found = false;
    final next = days.map((day) {
      if (_sameDate(day.date, updated.date)) {
        found = true;
        return updated;
      }
      return day;
    }).toList();

    if (!found) next.add(updated);
    return next;
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
    final completed = _prayerDay?.completedCount ?? 0;
    final progress = _prayerDay?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: _PrayerColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _PrayerBackdrop()),
          SafeArea(
            bottom: false,
            child: _loading
                ? const _PrayerLoading()
                : RefreshIndicator(
                    onRefresh: _loadPrayerData,
                    color: _PrayerColors.primary,
                    backgroundColor: _PrayerColors.surfaceHigh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 116),
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
                        const SizedBox(height: 22),
                        _ProgressPanel(
                          completed: completed,
                          progress: progress,
                          nextPrayer: _nextPrayer?.name,
                          nextPrayerTime: _nextPrayer?.timeLabel,
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(
                          title: 'Daily Sequence',
                          trailing: '$completed of ${_prayers.length}',
                        ),
                        const SizedBox(height: 10),
                        for (final prayer in _prayers) ...[
                          _PrayerRow(
                            prayer: prayer,
                            isDone:
                                _prayerDay?.prayerValue(prayer.name) ?? false,
                            isBusy: _toggling,
                            onTap: () => _togglePrayer(prayer.name),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 12),
                        _HistoryPreview(
                          activeDate: _activeDate,
                          historyDays: _historyDays,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  _PrayerMeta? get _nextPrayer {
    for (final prayer in _prayers) {
      if (!(_prayerDay?.prayerValue(prayer.name) ?? false)) return prayer;
    }
    return null;
  }
}

class _PrayerMeta {
  const _PrayerMeta(this.name, this.timeLabel, this.icon);

  final String name;
  final String timeLabel;
  final IconData icon;
}

class _PrayerColors {
  static const background = Color(0xFF0A0A12);
  static const surface = Color(0xFF141422);
  static const surfaceHigh = Color(0xFF1E1E30);
  static const surfaceHighest = Color(0xFF28283E);
  static const primary = Color(0xFFFF2D78);
  static const primarySoft = Color(0xFFFF80AA);
  static const secondary = Color(0xFF00FFCC);
  static const foreground = Color(0xFFE8E0F0);
  static const muted = Color(0xFFA098B0);
  static const outline = Color(0xFF302840);
  static const grid = Color(0x242A2434);
}

class _PrayerBackdrop extends StatelessWidget {
  const _PrayerBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _PrayerColors.background,
        gradient: RadialGradient(
          center: const Alignment(0, -1.08),
          radius: 1.05,
          colors: [
            _PrayerColors.primary.withValues(alpha: 0.18),
            _PrayerColors.background.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ),
      ),
      child: const CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _PrayerColors.grid
      ..strokeWidth = 1;
    const gap = 40.0;

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

class _PrayerHeader extends StatelessWidget {
  const _PrayerHeader({required this.dateLabel, required this.onHistoryTap});

  final String dateLabel;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _PrayerColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _PrayerColors.primary.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: _PrayerColors.primary.withValues(alpha: 0.16),
                  blurRadius: 22,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/archivum_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.auto_awesome_rounded,
                  color: _PrayerColors.primarySoft,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ARCHIVUM',
                  style: TextStyle(
                    color: _PrayerColors.primarySoft,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: _PrayerColors.muted.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Prayer history',
            child: IconButton(
              onPressed: onHistoryTap,
              style: IconButton.styleFrom(
                backgroundColor: _PrayerColors.surface.withValues(alpha: 0.72),
                foregroundColor: _PrayerColors.secondary,
                side: BorderSide(
                  color: _PrayerColors.outline.withValues(alpha: 0.9),
                ),
              ),
              icon: const Icon(Icons.history_rounded, size: 21),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.completed,
    required this.progress,
    required this.nextPrayer,
    required this.nextPrayerTime,
  });

  final int completed;
  final double progress;
  final String? nextPrayer;
  final String? nextPrayerTime;

  @override
  Widget build(BuildContext context) {
    final isComplete = completed == 5;

    return _NeonPanel(
      borderColor: _PrayerColors.primary.withValues(alpha: 0.44),
      glowColor: _PrayerColors.primary.withValues(alpha: 0.17),
      child: Column(
        children: [
          SizedBox(
            width: 196,
            height: 196,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ProgressRing(progress: progress),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: _PrayerColors.primarySoft,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: _PrayerColors.primary, blurRadius: 14),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Daily Core',
                      style: TextStyle(
                        color: _PrayerColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _NextPrayerBanner(
            title: isComplete
                ? 'Daily sequence complete'
                : '${nextPrayer ?? 'Prayer'} is next',
            message: isComplete
                ? "Masha'Allah, all prayers are complete for today."
                : nextPrayerTime == null
                ? 'Keep your day steady.'
                : 'Scheduled at $nextPrayerTime',
            isComplete: isComplete,
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _ProgressRingPainter(progress: value),
          size: const Size.square(196),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = _PrayerColors.primary.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = _PrayerColors.primary.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final progressPaint = Paint()
      ..color = _PrayerColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    final sweep = math.pi * 2 * progress;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NextPrayerBanner extends StatelessWidget {
  const _NextPrayerBanner({
    required this.title,
    required this.message,
    required this.isComplete,
  });

  final String title;
  final String message;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? _PrayerColors.secondary : _PrayerColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(
            isComplete
                ? Icons.verified_rounded
                : Icons.notifications_active_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: _PrayerColors.muted,
                    fontSize: 13,
                    height: 1.25,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _PrayerColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _PrayerColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              color: _PrayerColors.primarySoft,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.isDone,
    required this.isBusy,
    required this.onTap,
  });

  final _PrayerMeta prayer;
  final bool isDone;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isDone ? _PrayerColors.primary : _PrayerColors.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isBusy && !isDone ? 0.72 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _PrayerColors.surfaceHigh.withValues(
                alpha: isDone ? 0.95 : 0.82,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDone
                    ? _PrayerColors.primary.withValues(alpha: 0.5)
                    : _PrayerColors.outline.withValues(alpha: 0.86),
              ),
              boxShadow: isDone
                  ? [
                      BoxShadow(
                        color: _PrayerColors.primary.withValues(alpha: 0.16),
                        blurRadius: 18,
                        spreadRadius: -6,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(prayer.icon, color: accent.withValues(alpha: 0.88)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.name,
                        style: const TextStyle(
                          color: _PrayerColors.foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        prayer.timeLabel,
                        style: TextStyle(
                          color: isDone
                              ? _PrayerColors.primarySoft
                              : _PrayerColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _PrayerToggle(isDone: isDone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerToggle extends StatelessWidget {
  const _PrayerToggle({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 26,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDone
            ? _PrayerColors.primary.withValues(alpha: 0.2)
            : _PrayerColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone
              ? _PrayerColors.primary.withValues(alpha: 0.55)
              : _PrayerColors.outline,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: isDone ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isDone
                ? _PrayerColors.primary
                : _PrayerColors.muted.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(5),
            boxShadow: isDone
                ? [
                    BoxShadow(
                      color: _PrayerColors.primary.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({required this.activeDate, required this.historyDays});

  final DateTime activeDate;
  final List<PrayerDay> historyDays;

  @override
  Widget build(BuildContext context) {
    final byDate = {
      for (final day in historyDays) _dateKey(day.date): day.completedCount,
    };
    final dates = List.generate(
      28,
      (index) => activeDate.subtract(Duration(days: 27 - index)),
    );

    return _NeonPanel(
      borderColor: _PrayerColors.outline.withValues(alpha: 0.88),
      glowColor: _PrayerColors.secondary.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Archival History',
                  style: TextStyle(
                    color: _PrayerColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _LegendSwatch(alpha: 0.14),
              const SizedBox(width: 5),
              _LegendSwatch(alpha: 0.44),
              const SizedBox(width: 5),
              _LegendSwatch(alpha: 1),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final count = byDate[_dateKey(date)];
              return Tooltip(
                message: count == null
                    ? '${_shortDate(date)}, no record'
                    : '${_shortDate(date)}, $count of 5',
                child: _HistoryCell(completedCount: count),
              );
            },
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekLabel('Week 1'),
              _WeekLabel('Week 2'),
              _WeekLabel('Week 3'),
              _WeekLabel('Week 4'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCell extends StatelessWidget {
  const _HistoryCell({required this.completedCount});

  final int? completedCount;

  @override
  Widget build(BuildContext context) {
    final alpha = switch (completedCount) {
      null => 0.08,
      0 => 0.12,
      1 || 2 => 0.24,
      3 || 4 => 0.54,
      _ => 1.0,
    };
    final color = completedCount == null
        ? _PrayerColors.surfaceHighest
        : _PrayerColors.primary.withValues(alpha: alpha);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: _PrayerColors.outline.withValues(alpha: 0.55),
        ),
        boxShadow: completedCount == 5
            ? [
                BoxShadow(
                  color: _PrayerColors.primary.withValues(alpha: 0.42),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.alpha});

  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _PrayerColors.primary.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(3),
        boxShadow: alpha == 1
            ? [
                BoxShadow(
                  color: _PrayerColors.primary.withValues(alpha: 0.45),
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _PrayerColors.muted.withValues(alpha: 0.62),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _NeonPanel extends StatelessWidget {
  const _NeonPanel({
    required this.child,
    required this.borderColor,
    required this.glowColor,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Color borderColor;
  final Color glowColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _PrayerColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 24, spreadRadius: -3),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrayerLoading extends StatelessWidget {
  const _PrayerLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: _PrayerColors.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _PrayerColors.primary.withValues(alpha: 0.42),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: _PrayerColors.primary,
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}
