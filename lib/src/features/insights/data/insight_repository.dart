import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/insight_data.dart';

class InsightRepository {
  final SupabaseClient client;

  InsightRepository(this.client);

  /// Calls the `get_insights` RPC function and returns parsed [InsightData].
  Future<InsightData> fetchInsights() async {
    final response = await client.rpc('get_insights');
    return InsightData.fromJson(response as Map<String, dynamic>);
  }
}
