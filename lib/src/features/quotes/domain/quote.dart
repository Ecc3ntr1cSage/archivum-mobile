class Quote {
  final String? id;
  final String? userId;
  final String content;
  final String? author;
  final String? tag;
  final String? color;
  final DateTime? createdAt;

  Quote({
    this.id,
    this.userId,
    required this.content,
    this.author,
    this.tag,
    this.color,
    this.createdAt,
  });

  Quote copyWith({
    String? id,
    String? userId,
    String? content,
    String? author,
    String? tag,
    String? color,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      author: author ?? this.author,
      tag: tag ?? this.tag,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
