import 'package:flutter_test/flutter_test.dart';

import 'package:archivum_mobile/src/features/prayers/presentation/prayer_intensity.dart';

void main() {
  test('uses the standard gray-to-green prayer intensity scale', () {
    expect(PrayerIntensityColors.forCount(0), PrayerIntensityColors.zero);
    expect(PrayerIntensityColors.forCount(1), PrayerIntensityColors.one);
    expect(PrayerIntensityColors.forCount(2), PrayerIntensityColors.two);
    expect(PrayerIntensityColors.forCount(3), PrayerIntensityColors.three);
    expect(PrayerIntensityColors.forCount(4), PrayerIntensityColors.four);
    expect(PrayerIntensityColors.forCount(5), PrayerIntensityColors.five);
    expect(
      PrayerIntensityColors.forCount(null),
      PrayerIntensityColors.noRecord,
    );
  });
}
