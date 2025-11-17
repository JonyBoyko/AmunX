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
