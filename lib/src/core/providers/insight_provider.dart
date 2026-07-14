import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/insights/data/insight_repository.dart';
import '../../features/insights/domain/insight_data.dart';
import 'supabase_provider.dart';

final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return InsightRepository(client);
});

/// Provides the insight data as a [FutureProvider] so the UI can show
/// loading / error / data states.
final insightDataProvider = FutureProvider<InsightData>((ref) {
  final repo = ref.watch(insightRepositoryProvider);
  return repo.fetchInsights();
});
