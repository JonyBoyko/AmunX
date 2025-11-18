import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../services/livekit_service.dart';

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
        SnackBar(content: Text('Не вдалося запустити live: $error')),
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
                    _TranscriptPanel(
                      status: state.status,
                      segments: state.transcript,
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
      LivekitStatus.connecting => 'Зʼєднуємося з LiveKit…',
      LivekitStatus.error => error ?? 'Сталася помилка',
      _ => 'У прямому ефірі'
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
                '$listeners слухачів',
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

class _TranscriptPanel extends StatelessWidget {
  const _TranscriptPanel({
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
              'Щойно ви почнете говорити, тут зʼявиться текст.',
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
          onPressed: status == LivekitStatus.connecting ? null : () => onEnd(),
          child: status == LivekitStatus.connecting
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
