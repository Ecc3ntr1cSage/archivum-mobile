class PrayerDay {
  final int? id;
  final String? userId;
  final DateTime date;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;

  const PrayerDay({
    this.id,
    this.userId,
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
  });

  int get completedCount =>
      [fajr, dhuhr, asr, maghrib, isha].where((v) => v).length;

  double get progress => completedCount / 5;

  bool prayerValue(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return fajr;
      case 'dhuhr':
        return dhuhr;
      case 'asr':
        return asr;
      case 'maghrib':
        return maghrib;
      case 'isha':
        return isha;
      default:
        return false;
    }
  }

  PrayerDay copyWithPrayer(String name, bool value) {
    return PrayerDay(
      id: id,
      userId: userId,
      date: date,
      fajr: name.toLowerCase() == 'fajr' ? value : fajr,
      dhuhr: name.toLowerCase() == 'dhuhr' ? value : dhuhr,
      asr: name.toLowerCase() == 'asr' ? value : asr,
      maghrib: name.toLowerCase() == 'maghrib' ? value : maghrib,
      isha: name.toLowerCase() == 'isha' ? value : isha,
    );
  }

  factory PrayerDay.fromMap(Map<String, dynamic> map) {
    return PrayerDay(
      id: map['id'] as int?,
      userId: map['user_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      fajr: (map['fajr'] as bool?) ?? false,
      dhuhr: (map['dhuhr'] as bool?) ?? false,
      asr: (map['asr'] as bool?) ?? false,
      maghrib: (map['maghrib'] as bool?) ?? false,
      isha: (map['isha'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'date': _formatDate(date),
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
