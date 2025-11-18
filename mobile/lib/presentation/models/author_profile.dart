import 'package:flutter/material.dart';

@immutable
class AuthorProfile {
  final String id;
  final String displayName;
  final String handle;
  final String bio;
  final String avatarEmoji;
  final String? avatarUrl;
  final int followers;
  final int following;
  final int posts;
  final bool isFollowed;
  final bool isLive;
  final List<String> badges;
  final Map<String, String> socialLinks;

  const AuthorProfile({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.avatarEmoji,
    this.avatarUrl,
    required this.followers,
    required this.following,
    required this.posts,
    required this.isFollowed,
    required this.isLive,
    required this.badges,
    this.socialLinks = const {},
  });

  AuthorProfile copyWith({
    String? displayName,
    String? handle,
    String? bio,
    String? avatarEmoji,
    String? avatarUrl,
    int? followers,
    int? following,
    int? posts,
    bool? isFollowed,
    bool? isLive,
    List<String>? badges,
    Map<String, String>? socialLinks,
  }) {
    return AuthorProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      isFollowed: isFollowed ?? this.isFollowed,
      isLive: isLive ?? this.isLive,
      badges: badges ?? this.badges,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}
