import 'package:flutter/foundation.dart';

@immutable
class LiveRoom {
  final String id;
  final String hostId;
  final String hostName;
  final String handle;
  final String topic;
  final String emoji;
  final int listeners;
  final String city;
  final bool isFollowedHost;
  final DateTime startedAt;
  final List<String> tags;
  final bool isSimulated;

  const LiveRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.handle,
    required this.topic,
    required this.emoji,
    required this.listeners,
    required this.city,
    required this.isFollowedHost,
    required this.startedAt,
    required this.tags,
    this.isSimulated = false,
  });

  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    return LiveRoom(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      hostName: json['host_name'] as String? ?? '',
      handle: json['host_handle'] as String? ?? '',
      topic: (json['title'] as String?)?.isNotEmpty == true
          ? json['title'] as String
          : 'Live session',
      emoji: _emojiForMask(json['mask'] as String? ?? 'none'),
      listeners: json['listeners'] as int? ?? 0,
      city: json['city'] as String? ?? 'Online',
      isFollowedHost: json['is_followed_host'] as bool? ?? false,
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      isSimulated: false,
    );
  }

  LiveRoom copyWith({
    String? hostName,
    String? handle,
    String? topic,
    String? emoji,
    int? listeners,
    String? city,
    bool? isFollowedHost,
    DateTime? startedAt,
    List<String>? tags,
    bool? isSimulated,
  }) {
    return LiveRoom(
      id: id,
      hostId: hostId,
      hostName: hostName ?? this.hostName,
      handle: handle ?? this.handle,
      topic: topic ?? this.topic,
      emoji: emoji ?? this.emoji,
      listeners: listeners ?? this.listeners,
      city: city ?? this.city,
      isFollowedHost: isFollowedHost ?? this.isFollowedHost,
      startedAt: startedAt ?? this.startedAt,
      tags: tags ?? this.tags,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }
}

String _emojiForMask(String mask) {
  switch (mask) {
    case 'studio':
      return '🎙️';
    case 'basic':
      return '🔊';
    default:
      return '🔴';
  }
}
