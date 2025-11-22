import 'dart:ui';

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
  ConsumerState<LiveListenerScreen> createState() => _LiveListenerScreenState();
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
        body: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
            SafeArea(
              child: Center(
                child: _GlassPanel(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceXl),
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
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            left: -90,
            top: 40,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -70,
            bottom: -60,
            child: Opacity(
              opacity: 0.18,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.bgPopover, AppTheme.neonBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLg,
                    vertical: AppTheme.spaceSm,
                  ),
                  child: _ListenerHeader(onBack: () => context.pop()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLg,
                    vertical: AppTheme.spaceSm,
                  ),
                  child: _ConnectionBanner(
                    status: state.status,
                    error: state.error,
                    onRetry: state.status == LivekitStatus.error
                        ? () => _joinRoom(retry: true)
                        : null,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spaceXl),
                    child: Column(
                      children: [
                        _HostCard(room: room, state: state),
                        const SizedBox(height: AppTheme.spaceXl),
                        _GlassPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            child: LiveTranscriptPanel(
                              status: state.status,
                              segments: state.transcript,
                              emptyLabel:
                                  'Captions will appear here once the host starts talking.',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXl),
                        // AI Summary Block (згідно з макетом)
                        _AISummaryBlock(
                          summary: 'Команда обговорила пропозицію створити окремий екран для AI налаштувань. Всі підтримали ідею та домовились обговорити деталі на наступній зустрічі.',
                        ),
                        const SizedBox(height: AppTheme.spaceXl),
                        const _ReactionPanel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // FAB "Add episode" - згідно з макетом
          Positioned(
            right: 16,
            bottom: 96,
            child: _AddEpisodeFab(
              onTap: () {
                // TODO: Navigate to record screen
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenerHeader extends StatelessWidget {
  const _ListenerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
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
                gradient: const LinearGradient(
                  colors: [AppTheme.neonPink, AppTheme.neonBlue],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  ...AppTheme.glowPrimary,
                  ...AppTheme.glowAccent,
                ],
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.textInverse,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.94, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _GlassPanel(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            gradient: const LinearGradient(
              colors: [AppTheme.glassSurface, AppTheme.glassSurfaceDense],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.2),
                    child: Text(
                      room.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${room.handle.replaceFirst('@', '')}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        room.hostName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                      vertical: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.glassStroke),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hearing, size: 16, color: AppTheme.neonBlue),
                        const SizedBox(width: 6),
                        Text(
                          '${state.listenerCount} listening',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                room.topic,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.status == LivekitStatus.connecting
                    ? 'Connecting to LiveKit...'
                    : state.status == LivekitStatus.reconnecting
                        ? 'Trying to reconnect to LiveKit...'
                        : state.status == LivekitStatus.error
                            ? (state.error ?? 'Connection lost')
                            : 'Live and transcribing',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionPanel extends StatelessWidget {
  const _ReactionPanel();

  @override
  Widget build(BuildContext context) {
    const reactions = ['🔥', '👏', '😂', '😮', '❤️'];
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live reactions',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: reactions
                  .map(
                    (emoji) => TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 240),
                      tween: Tween(begin: 0.9, end: 1),
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.glassSurfaceDense,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.glassStroke),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AISummaryBlock extends StatelessWidget {
  final String summary;

  const _AISummaryBlock({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: AppTheme.glassSurfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border(
            left: BorderSide(
              color: AppTheme.neonBlue,
              width: 4,
            ),
            top: BorderSide(
              color: AppTheme.glassStroke,
              width: 1,
            ),
            right: BorderSide(
              color: AppTheme.glassStroke,
              width: 1,
            ),
            bottom: BorderSide(
              color: AppTheme.glassStroke,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppTheme.neonBlue,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Text(
                  'AI Summary',
                  style: TextStyle(
                    color: AppTheme.neonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              summary,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEpisodeFab extends StatelessWidget {
  final VoidCallback onTap;

  const _AddEpisodeFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppTheme.neonGradient,
          shape: BoxShape.circle,
          boxShadow: [
            ...AppTheme.glowPrimary,
            ...AppTheme.glowAccent,
          ],
        ),
        child: const Icon(
          Icons.add,
          color: AppTheme.textInverse,
          size: 32,
        ),
      ),
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
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSm),
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.blurMd,
          sigmaY: AppTheme.blurMd,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 28,
                offset: Offset(0, 18),
                spreadRadius: -8,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
