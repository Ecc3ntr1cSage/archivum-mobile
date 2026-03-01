import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/indexes/domain/index_repository.dart';
import '../../features/indexes/data/index_repository.dart';
import 'supabase_provider.dart';

final indexRepositoryProvider = Provider<IndexRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseIndexRepository(client);
});
