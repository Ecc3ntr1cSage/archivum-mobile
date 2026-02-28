import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/solat_day.dart';

class SolatRepository {
  final SupabaseClient client;
  SolatRepository(this.client);

  Future<void> upsertSolatDay(SolatDay d) async {
    await client.from('solat_days').upsert({
      'id': d.id,
      'date': d.date.toIso8601String(),
      'fajr': d.fajr,
      'dhuhr': d.dhuhr,
      'asr': d.asr,
      'maghrib': d.maghrib,
      'isha': d.isha,
    });
  }
}
