import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/insight_data.dart';

class InsightRepository {
  final SupabaseClient client;

  InsightRepository(this.client);

  /// Calls the `get_insights` RPC function and returns parsed [InsightData].
  Future<InsightData> fetchInsights() => guardAppError(() async {
    final response = await client.rpc('get_insights');
    return InsightData.fromJson(response as Map<String, dynamic>);
  });
}
