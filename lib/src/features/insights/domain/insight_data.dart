/// Represents a tag breakdown item (e.g. "flutter: 5").
class TagBreakdown {
  final String tag;
  final int count;

  const TagBreakdown({required this.tag, required this.count});

  factory TagBreakdown.fromJson(Map<String, dynamic> json) {
    return TagBreakdown(
      tag: json['tag'] as String? ?? json['method'] as String? ?? json['provider'] as String? ?? json['feature'] as String? ?? 'unknown',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Holds all aggregated insight data returned from the RPC call.
class InsightData {
  final int totalNotes;
  final int totalContent;
  final int totalIndexes;
  final int totalIndexItems;
  final int totalPrayers;
  final int totalPrayerDays;
  final double avgDailyPrayers;
  final int longestStreak;
  final double completionRate;
  final int totalAccounts;
  final int totalTags;
  final List<TagBreakdown> noteTags;
  final List<TagBreakdown> accountMethods;
  final List<TagBreakdown> ssoProviders;
  final List<TagBreakdown> tagFeatures;

  const InsightData({
    required this.totalNotes,
    required this.totalContent,
    required this.totalIndexes,
    required this.totalIndexItems,
    required this.totalPrayers,
    required this.totalPrayerDays,
    required this.avgDailyPrayers,
    required this.longestStreak,
    required this.completionRate,
    required this.totalAccounts,
    required this.totalTags,
    required this.noteTags,
    required this.accountMethods,
    required this.ssoProviders,
    required this.tagFeatures,
  });

  factory InsightData.fromJson(Map<String, dynamic> json) {
    return InsightData(
      totalNotes: (json['total_notes'] as num?)?.toInt() ?? 0,
      totalContent: (json['total_content'] as num?)?.toInt() ?? 0,
      totalIndexes: (json['total_indexes'] as num?)?.toInt() ?? 0,
      totalIndexItems: (json['total_index_items'] as num?)?.toInt() ?? 0,
      totalPrayers: (json['total_prayers'] as num?)?.toInt() ?? 0,
      totalPrayerDays: (json['total_prayer_days'] as num?)?.toInt() ?? 0,
      avgDailyPrayers: (json['avg_daily_prayers'] as num?)?.toDouble() ?? 0.0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      totalAccounts: (json['total_accounts'] as num?)?.toInt() ?? 0,
      totalTags: (json['total_tags'] as num?)?.toInt() ?? 0,
      noteTags: _parseBreakdownList(json['note_tags']),
      accountMethods: _parseBreakdownList(json['account_methods']),
      ssoProviders: _parseBreakdownList(json['sso_providers']),
      tagFeatures: _parseBreakdownList(json['tag_features']),
    );
  }

  static List<TagBreakdown> _parseBreakdownList(dynamic list) {
    if (list == null || list is! List) return [];
    return list
        .map((item) => TagBreakdown.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
