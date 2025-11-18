import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../models/live_room.dart';
import '../providers/live_rooms_provider.dart';
import '../services/livekit_service.dart';
import '../widgets/live_transcript_panel.dart';

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
    ref.listen<LivekitSessionState>(
      livekitControllerProvider,
      _handleStatusChange,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinRoom());
  }

  Future<void> _joinRoom({bool retry = false}) async {
    final rooms = ref.read(liveRoomsProvider);
    _resolvedRoom = widget.room ?? (rooms.isNotEmpty ? rooms.first : null);
    final sessionId = _resolvedRoom?.id;
    if (sessionId == null) {
      return;
    }
    if (retry && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Retrying connection...')),
      );
    }
    try {
      await ref.read(livekitControllerProvider.notifier).joinSession(sessionId);
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to join live: $error')),
      );
    }
  }

  @override
  void dispose() {
    ref.read(livekitControllerProvider.notifier).leave();
    super.dispose();
  }

  void _handleStatusChange(
    LivekitSessionState? previous,
    LivekitSessionState next,
  ) {
    if (!mounted) {
      return;
    }
    if (next.status == LivekitStatus.reconnecting &&
        previous?.status != LivekitStatus.reconnecting) {
      _showStatusSnackBar(
        'Trying to reconnect to LiveKit...',
        actionLabel: 'Retry',
        onAction: () => _joinRoom(retry: true),
      );
      return;
    }
    if (previous?.status == LivekitStatus.reconnecting &&
        next.status == LivekitStatus.connected) {
      _showStatusSnackBar('Reconnected to LiveKit');
    }
  }

  void _showStatusSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
    });
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
                  'No live sessions are active right now.',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go back'),
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
            _ConnectionBanner(
              status: state.status,
              error: state.error,
              onRetry: state.status == LivekitStatus.error
                  ? () => _joinRoom(retry: true)
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  children: [
                    _HostCard(room: room, state: state),
                    const SizedBox(height: AppTheme.spaceXl),
                    LiveTranscriptPanel(
                      status: state.status,
                      segments: state.transcript,
                      emptyLabel:
                          'Captions will appear here once the host starts talking.',
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
            '${state.listenerCount} listeners tuned in',
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
                'Connecting to LiveKit...',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else if (state.status == LivekitStatus.reconnecting)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Trying to reconnect to LiveKit...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
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
          'Live reactions',
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

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.status,
    required this.error,
    this.onRetry,
  });

  final LivekitStatus status;
  final String? error;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == LivekitStatus.connected) {
      return const SizedBox.shrink();
    }
    final message = switch (status) {
      LivekitStatus.connecting => 'Connecting to LiveKit...',
      LivekitStatus.reconnecting => 'Trying to reconnect to LiveKit...',
      LivekitStatus.error => error ?? 'Connection lost. Please retry.',
      _ => '',
    };
    if (message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceSm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSm),
        decoration: BoxDecoration(
          color: AppTheme.bgRaised,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(
              status == LivekitStatus.error
                  ? Icons.warning_amber_outlined
                  : Icons.wifi_tethering,
              color: AppTheme.brandAccent,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            if (status == LivekitStatus.error && onRetry != null)
              TextButton(
                onPressed: () => onRetry!(),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
