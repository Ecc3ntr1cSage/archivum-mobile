import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/prayers/data/prayer_repository.dart';
import 'supabase_provider.dart';

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PrayerRepository(client);
});
