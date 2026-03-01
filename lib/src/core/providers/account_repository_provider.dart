import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/accounts/domain/account_repository.dart';
import '../../features/accounts/data/account_repository.dart';
import 'supabase_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAccountRepository(client);
});
