import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/prayer_day.dart';

/// Returns the "active" prayer date.
/// If the current local time is before 05:00, the active date is yesterday
/// (so Isha prayed after midnight still counts for the previous day).
/// The new day resets at 05:00.
DateTime getActiveDate() {
  final now = DateTime.now();
  if (now.hour < 5) {
    final yesterday = now.subtract(const Duration(days: 1));
    return DateTime(yesterday.year, yesterday.month, yesterday.day);
  }
  return DateTime(now.year, now.month, now.day);
}

class PrayerRepository {
  final SupabaseClient client;
  PrayerRepository(this.client);

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Fetch prayer record for [date]. Returns null if none exists.
  Future<PrayerDay?> fetchPrayerDay(DateTime date) async {
    final dateStr = _formatDate(date);
    final res = await client
        .from('prayers')
        .select()
        .eq('date', dateStr)
        .maybeSingle();
    if (res == null) return null;
    return PrayerDay.fromMap(res);
  }

  /// Fetch existing record for [date], or insert a blank one and return it.
  Future<PrayerDay> fetchOrCreatePrayerDay(DateTime date) async {
    final existing = await fetchPrayerDay(date);
    if (existing != null) return existing;

    final blank = PrayerDay(date: date);
    final inserted = await client
        .from('prayers')
        .insert(blank.toInsertMap())
        .select()
        .single();
    return PrayerDay.fromMap(inserted);
  }

  /// Update a single prayer column for the record with [id].
  Future<PrayerDay> updatePrayer(
      int id, String prayerName, bool value) async {
    final updated = await client
        .from('prayers')
        .update({prayerName.toLowerCase(): value})
        .eq('id', id)
        .select()
        .single();
    return PrayerDay.fromMap(updated);
  }

  /// Fetch all prayer records for [year]/[month].
  Future<List<PrayerDay>> fetchPrayersForMonth(int year, int month) async {
    final lastDay = DateTime(year, month + 1, 0).day;
    final from =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final to =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final res = await client
        .from('prayers')
        .select()
        .gte('date', from)
        .lte('date', to)
        .order('date');

    return (res as List)
        .map((m) => PrayerDay.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Returns (totalPrayersCompleted, totalDaysRecorded) across all time.
  Future<(int, int)> fetchAllTimeStats() async {
    final res = await client.from('prayers').select();
    final days = (res as List)
        .map((m) => PrayerDay.fromMap(m as Map<String, dynamic>))
        .toList();
    final totalCompleted =
        days.fold<int>(0, (sum, d) => sum + d.completedCount);
    return (totalCompleted, days.length);
  }
}
