class Comment {
  final String id;
  final String episodeId;
  final String authorId;
  final String authorName;
  final String authorHandle;
  final String? authorAvatar;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.episodeId,
    required this.authorId,
    required this.authorName,
    required this.authorHandle,
    required this.text,
    required this.createdAt,
    this.authorAvatar,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      episodeId: json['episode_id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String? ?? 'Creator',
      authorHandle: json['author_handle'] as String? ?? '@creator',
      authorAvatar: json['author_avatar'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
