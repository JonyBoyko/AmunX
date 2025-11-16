import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../models/live_room.dart';
import '../providers/live_rooms_provider.dart';

class LiveListenerScreen extends ConsumerWidget {
  final LiveRoom? room;

  const LiveListenerScreen({super.key, this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(liveRoomsProvider);
    final activeRoom = room ?? (rooms.isNotEmpty ? rooms.first : null);

    if (activeRoom == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgBase,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Немає live-трансляцій',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Назад'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  children: [
                    _buildHostCard(activeRoom),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildTranscriptPreview(activeRoom),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildReactions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.stateDanger,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                  color: AppTheme.textInverse, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard(LiveRoom room) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white24,
            child: Text(room.emoji,
                style: const TextStyle(color: Colors.white, fontSize: 24)),
          ),
          const SizedBox(width: AppTheme.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.hostName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  room.topic,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '${room.listeners} слухачів • ${room.city}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptPreview(LiveRoom room) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Translate',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '🔴 ${room.topic}\n${room.tags.join(' • ')}',
            style: const TextStyle(color: AppTheme.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.surfaceBorder),
          const SizedBox(height: 12),
          const Text(
            'Переклад доступний у записі (stub).',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    final reactions = ['👍', '🔥', '💡', '❤️', '👏'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Реакції',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Wrap(
          spacing: 12,
          children: reactions
              .map(
                (emoji) => GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.bgRaised,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
