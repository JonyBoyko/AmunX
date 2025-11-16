import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class LiveHostScreen extends StatefulWidget {
  const LiveHostScreen({super.key});

  @override
  State<LiveHostScreen> createState() => _LiveHostScreenState();
}

class _LiveHostScreenState extends State<LiveHostScreen> {
  int _duration = 0;
  int _listeners = 12;
  bool _isMuted = false;
  final List<_ReactionBubble> _reactions = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _duration++;
        _listeners = max(1, _listeners + Random().nextInt(3) - 1);
        if (Random().nextBool()) {
          _reactions.add(
            _ReactionBubble(
              emoji: ['👍', '🔥', '💡', '❤️'][Random().nextInt(4)],
              key: UniqueKey(),
            ),
          );
          if (_reactions.length > 6) {
            _reactions.removeAt(0);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_duration ~/ 60).toString().padLeft(2, '0');
    final secs = (_duration % 60).toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader('$mins:$secs'),
                Expanded(child: _buildContent()),
              ],
            ),
            ..._reactions,
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
            style: TextStyle(color: AppTheme.stateDanger, fontWeight: FontWeight.bold),
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

  Widget _buildContent() {
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
                  '$_listeners слухачів',
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
              children: const [
                Text('Чат', style: TextStyle(color: AppTheme.textSecondary)),
                SizedBox(height: AppTheme.spaceSm),
                Text('Марія: Чудова тема! 👏', style: TextStyle(color: AppTheme.textPrimary)),
                SizedBox(height: 4),
                Text('Олексій: Питання про AI?', style: TextStyle(color: AppTheme.textPrimary)),
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
                  backgroundColor: _isMuted ? AppTheme.stateDanger : AppTheme.surfaceChip,
                ),
                onPressed: () => setState(() => _isMuted = !_isMuted),
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
                onPressed: () => context.pop(),
                child: const Icon(Icons.call_end, color: AppTheme.textInverse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReactionBubble extends StatefulWidget {
  final String emoji;

  const _ReactionBubble({
    required this.emoji,
    required super.key,
  });

  @override
  State<_ReactionBubble> createState() => _ReactionBubbleState();
}

class _ReactionBubbleState extends State<_ReactionBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final left = random.nextDouble() * MediaQuery.of(context).size.width * 0.8;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(_controller.value);
        return Positioned(
          bottom: 80 + progress * 300,
          left: left,
          child: Opacity(
            opacity: 1 - progress,
            child: Transform.scale(
              scale: 1 + progress * 0.5,
              child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

