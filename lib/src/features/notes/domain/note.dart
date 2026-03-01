class Note {
  final String? id;
  final String? userId;
  final String title;
  final String content;
  final String? tag;
  final DateTime? createdAt;

  Note({
    this.id,
    this.userId,
    required this.title,
    required this.content,
    this.tag,
    this.createdAt,
  });

  Note copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? tag,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
