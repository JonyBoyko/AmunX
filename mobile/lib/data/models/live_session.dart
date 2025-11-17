class LiveSession {
  final String id;
  final String room;
  final String hostId;
  final String? topicId;
  final String? title;
  final String mask;
  final DateTime startedAt;

  const LiveSession({
    required this.id,
    required this.room,
    required this.hostId,
    required this.mask,
    required this.startedAt,
    this.topicId,
    this.title,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'] as String,
      room: json['room'] as String,
      hostId: json['host_id'] as String,
      topicId: json['topic_id'] as String?,
      title: json['title'] as String?,
      mask: json['mask'] as String? ?? 'none',
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class LiveSessionJoin {
  final LiveSession session;
  final String token;
  final String url;

  const LiveSessionJoin({
    required this.session,
    required this.token,
    required this.url,
  });

  factory LiveSessionJoin.fromJson(Map<String, dynamic> json) {
    return LiveSessionJoin(
      session: LiveSession.fromJson(
        Map<String, dynamic>.from(json['session'] as Map),
      ),
      token: json['token'] as String,
      url: json['url'] as String,
    );
  }
}
