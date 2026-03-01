import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/prayers/data/prayer_repository.dart';
import 'supabase_provider.dart';

final solatRepositoryProvider = Provider<SolatRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SolatRepository(client);
});
