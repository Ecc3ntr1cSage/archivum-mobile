import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

/// A single day's activity count.
class ActivityDay {
  final DateTime day;
  final int total;

  const ActivityDay({required this.day, required this.total});

  factory ActivityDay.fromJson(Map<String, dynamic> json) {
    return ActivityDay(
      day: DateTime.parse(json['day'] as String),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Fetches the last 7 days of activity from the RPC function.
Future<List<ActivityDay>> _fetchActivityLast7Days(SupabaseClient client) async {
  final response = await client.rpc('get_activity_last_7_days');
  final list = response as List;
  return list
      .map((item) => ActivityDay.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// Provider for the last 7 days of activity data.
final activityLast7DaysProvider = FutureProvider<List<ActivityDay>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return _fetchActivityLast7Days(client);
});
