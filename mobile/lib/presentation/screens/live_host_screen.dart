import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../services/livekit_service.dart';
import '../widgets/live_transcript_panel.dart';

class LiveHostScreen extends ConsumerStatefulWidget {
  const LiveHostScreen({super.key});

  @override
  ConsumerState<LiveHostScreen> createState() => _LiveHostScreenState();
}

class _LiveHostScreenState extends ConsumerState<LiveHostScreen> {
  Timer? _timer;
  int _elapsed = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _startSession();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _elapsed++);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    ref.read(livekitControllerProvider.notifier).endHosting();
    super.dispose();
  }

  Future<void> _startSession() async {
    try {
      await ref.read(livekitControllerProvider.notifier).startHosting();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start live: $error')),
      );
      context.pop();
    }
  }

  Future<void> _toggleMute(LivekitStatus status) async {
    if (status != LivekitStatus.connected) {
      return;
    }
    setState(() => _muted = !_muted);
    await ref
        .read(livekitControllerProvider.notifier)
        .setMicrophoneEnabled(!_muted);
  }

  Future<void> _endSession() async {
    await ref.read(livekitControllerProvider.notifier).endHosting();
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livekitControllerProvider);
    final listeners = state.listenerCount + 1;
    final minutes = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(timerLabel: '$minutes:$seconds'),
            _ConnectionBanner(
              status: state.status,
              error: state.error,
              onRetry:
                  state.status == LivekitStatus.error ? _startSession : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  children: [
                    _AudienceCard(
                      listeners: listeners,
                      status: state.status,
                      error: state.error,
                    ),
                    const SizedBox(height: AppTheme.spaceXl),
                    LiveTranscriptPanel(
                      status: state.status,
                      segments: state.transcript,
                      emptyLabel:
                          'Your words will appear here once you start speaking.',
                    ),
                    const Spacer(),
                    _Controls(
                      muted: _muted,
                      status: state.status,
                      onMute: () => _toggleMute(state.status),
                      onEnd: _endSession,
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.timerLabel});

  final String timerLabel;

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
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.stateDanger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.stateDanger,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            timerLabel,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({
    required this.listeners,
    required this.status,
    this.error,
  });

  final int listeners;
  final LivekitStatus status;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (status) {
      LivekitStatus.connecting => 'Connecting to LiveKit...',
      LivekitStatus.reconnecting => 'Trying to reconnect to LiveKit...',
      LivekitStatus.error => error ?? 'Connection lost',
      _ => 'Session is live',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt, color: AppTheme.brandPrimary),
          const SizedBox(width: AppTheme.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$listeners listeners',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
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
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }
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

class _Controls extends StatelessWidget {
  const _Controls({
    required this.muted,
    required this.status,
    required this.onMute,
    required this.onEnd,
  });

  final bool muted;
  final LivekitStatus status;
  final VoidCallback onMute;
  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) {
    final isConnecting =
        status == LivekitStatus.connecting || status == LivekitStatus.reconnecting;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor:
                muted ? AppTheme.stateDanger : AppTheme.surfaceChip,
            padding: const EdgeInsets.all(20),
          ),
          onPressed: status == LivekitStatus.connected ? onMute : null,
          child: Icon(
            muted ? Icons.mic_off : Icons.mic,
            color: muted ? AppTheme.textInverse : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: AppTheme.spaceLg),
        FilledButton(
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: AppTheme.stateDanger,
            padding: const EdgeInsets.all(26),
          ),
          onPressed: isConnecting ? null : () => onEnd(),
          child: isConnecting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textInverse,
                  ),
                )
              : const Icon(Icons.call_end, color: AppTheme.textInverse),
        ),
      ],
    );
  }
}
