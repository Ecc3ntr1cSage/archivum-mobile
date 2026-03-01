class IndexEntry {
  final String? id;
  final String? userId;
  final String title;
  final List<IndexItem> items;
  final DateTime? createdAt;

  IndexEntry({
    this.id,
    this.userId,
    required this.title,
    this.items = const [],
    this.createdAt,
  });

  IndexEntry copyWith({
    String? id,
    String? userId,
    String? title,
    List<IndexItem>? items,
    DateTime? createdAt,
  }) {
    return IndexEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class IndexItem {
  final String? id;
  final String? indexId;
  final String item;
  final int? status;
  final DateTime? createdAt;

  IndexItem({
    this.id,
    this.indexId,
    required this.item,
    this.status,
    this.createdAt,
  });

  /// status: 0 or null = unchecked, 1 = checked
  bool get isChecked => status == 1;

  IndexItem copyWith({
    String? id,
    String? indexId,
    String? item,
    int? Function()? status,
    DateTime? createdAt,
  }) {
    return IndexItem(
      id: id ?? this.id,
      indexId: indexId ?? this.indexId,
      item: item ?? this.item,
      status: status != null ? status() : this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
