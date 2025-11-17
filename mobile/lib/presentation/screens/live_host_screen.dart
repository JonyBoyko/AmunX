import 'dart:async';
import 'dart:ui';

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
  int _duration = 0;
  bool _isMuted = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startHosting();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _duration++);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    ref.read(livekitControllerProvider.notifier).endHosting();
    super.dispose();
  }

  Future<void> _startHosting() async {
    try {
      await ref
          .read(livekitControllerProvider.notifier)
          .startHosting(title: 'Live AMA');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не вдалося запустити live: $e')),
      );
    }
  }

  Future<void> _toggleMute(LivekitStatus status) async {
    if (status != LivekitStatus.connected) return;
    setState(() => _isMuted = !_isMuted);
    await ref
        .read(livekitControllerProvider.notifier)
        .setMicrophoneEnabled(!_isMuted);
  }

  Future<void> _endSession() async {
    await ref.read(livekitControllerProvider.notifier).endHosting();
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(livekitControllerProvider);
    final mins = (_duration ~/ 60).toString().padLeft(2, '0');
    final secs = (_duration % 60).toString().padLeft(2, '0');
    final listeners = sessionState.listenerCount + 1;

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader('$mins:$secs'),
            Expanded(
              child: _buildContent(
                sessionState.status,
                sessionState.error,
                listeners,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String timerLabel) {
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
                color: AppTheme.stateDanger, fontWeight: FontWeight.bold),
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

  Widget _buildContent(
    LivekitStatus status,
    String? error,
    int listeners,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: AppTheme.bgRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt, color: AppTheme.brandPrimary),
                const SizedBox(width: AppTheme.spaceSm),
                Text(
                  '$listeners слухачів',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: AppTheme.bgRaised,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Тема',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: AppTheme.spaceSm),
                const Text('Live AMA: історії з комʼюніті',
                    style: TextStyle(color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.spaceSm),
                if (status == LivekitStatus.connecting)
                  const Text('Підключення до LiveKit…',
                      style: TextStyle(color: AppTheme.textSecondary))
                else if (status == LivekitStatus.error && error != null)
                  Text(error,
                      style: const TextStyle(color: AppTheme.stateDanger)),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor:
                      _isMuted ? AppTheme.stateDanger : AppTheme.surfaceChip,
                ),
                onPressed: status == LivekitStatus.connected
                    ? () => _toggleMute(status)
                    : null,
                child: Icon(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? AppTheme.textInverse : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: AppTheme.spaceLg),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: AppTheme.stateDanger,
                  padding: const EdgeInsets.all(24),
                ),
                onPressed: status == LivekitStatus.connecting
                    ? null
                    : () => _endSession(),
                child: status == LivekitStatus.connecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textInverse,
                        ),
                      )
                    : const Icon(Icons.call_end, color: AppTheme.textInverse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
