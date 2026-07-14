import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/insights/data/financial_insight_repository.dart';
import '../../features/insights/domain/financial_insight_data.dart';
import 'supabase_provider.dart';

final financialInsightRepositoryProvider =
    Provider<FinancialInsightRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FinancialInsightRepository(client);
});

final financialInsightDataProvider =
    FutureProvider<FinancialInsightData>((ref) {
  final repo = ref.watch(financialInsightRepositoryProvider);
  return repo.fetchFinancialInsights();
});
