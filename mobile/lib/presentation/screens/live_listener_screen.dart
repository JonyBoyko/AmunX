import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../models/live_room.dart';
import '../providers/live_rooms_provider.dart';
import '../services/livekit_service.dart';

class LiveListenerScreen extends ConsumerStatefulWidget {
  const LiveListenerScreen({super.key, this.room});

  final LiveRoom? room;

  @override
  ConsumerState<LiveListenerScreen> createState() =>
      _LiveListenerScreenState();
}

class _LiveListenerScreenState extends ConsumerState<LiveListenerScreen> {
  LiveRoom? _resolvedRoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinRoom());
  }

  Future<void> _joinRoom() async {
    final rooms = ref.read(liveRoomsProvider);
    _resolvedRoom = widget.room ?? (rooms.isNotEmpty ? rooms.first : null);
    final sessionId = _resolvedRoom?.id;
    if (sessionId == null) {
      return;
    }
    try {
      await ref.read(livekitControllerProvider.notifier).joinSession(sessionId);
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не вдалося приєднатися: $error')),
      );
    }
  }

  @override
  void dispose() {
    ref.read(livekitControllerProvider.notifier).leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(liveRoomsProvider);
    final room =
        _resolvedRoom ?? widget.room ?? (rooms.isNotEmpty ? rooms.first : null);
    final state = ref.watch(livekitControllerProvider);

    if (room == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgBase,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Немає активних live.',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Повернутись'),
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
            _ListenerHeader(onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  children: [
                    _HostCard(room: room, state: state),
                    const SizedBox(height: AppTheme.spaceXl),
                    _TranscriptFeed(
                      status: state.status,
                      segments: state.transcript,
                    ),
                    const SizedBox(height: AppTheme.spaceXl),
                    _ReactionPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenerHeader extends StatelessWidget {
  const _ListenerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd,
              vertical: AppTheme.spaceXs,
            ),
            decoration: BoxDecoration(
              color: AppTheme.stateDanger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: AppTheme.stateDanger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.room, required this.state});

  final LiveRoom room;
  final LivekitSessionState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room.topic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${room.handle.replaceFirst('@', '')}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.listenerCount} слухачів прямо зараз',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (state.status == LivekitStatus.error && state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          else if (state.status == LivekitStatus.connecting)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'З’єднання з LiveKit…',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

class _TranscriptFeed extends StatelessWidget {
  const _TranscriptFeed({
    required this.status,
    required this.segments,
  });

  final LivekitStatus status;
  final List<TranscriptSegment> segments;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live-транскрипт',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          if (status == LivekitStatus.connected && segments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: segments
                  .take(6)
                  .map(
                    (segment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TranscriptLine(segment: segment),
                    ),
                  )
                  .toList(),
            )
          else
            const Text(
              'Текст з’явиться, щойно розмова почнеться.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _TranscriptLine extends StatelessWidget {
  const _TranscriptLine({required this.segment});

  final TranscriptSegment segment;

  @override
  Widget build(BuildContext context) {
    final meta = _languageLabel(segment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          segment.speakerLabel,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          segment.text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        if (meta != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              meta,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReactionPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const reactions = ['👍', '🔥', '👏', '🤯', '❤️'];
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
                (emoji) => Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.bgRaised,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

String? _languageLabel(TranscriptSegment segment) {
  final language = segment.language?.trim();
  if (language == null || language.isEmpty) {
    return null;
  }
  final upper = language.toUpperCase();
  if (segment.isTranslation) {
    return 'Переклад ($upper)';
  }
  return upper;
}
