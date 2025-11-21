import 'dart:ui';

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
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            left: -100,
            top: -40,
            child: Opacity(
              opacity: 0.18,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -60,
            child: Opacity(
              opacity: 0.14,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.bgPopover, AppTheme.neonPurple],
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
                  child: _Header(timerLabel: '$minutes:$seconds'),
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
                        ? _startSession
                        : null,
                  ),
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
                        _GlassPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            child: LiveTranscriptPanel(
                              status: state.status,
                              segments: state.transcript,
                              emptyLabel:
                                  'Your words will appear here once you start speaking.',
                            ),
                          ),
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
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.timerLabel});

  final String timerLabel;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                gradient: AppTheme.neonGradient,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            const Text(
              'LIVE',
              style: TextStyle(
                color: AppTheme.stateDanger,
                fontWeight: FontWeight.w700,
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

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.93, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _GlassPanel(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            gradient: const LinearGradient(
              colors: [AppTheme.glassSurface, AppTheme.glassSurfaceDense],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.neonGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    ...AppTheme.glowPrimary,
                    ...AppTheme.glowAccent,
                  ],
                ),
                child: const Icon(Icons.people_alt, color: AppTheme.textInverse),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$listeners listeners',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }
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
        _NeonCircleButton(
          enabled: status == LivekitStatus.connected,
          onPressed: onMute,
          gradient: AppTheme.neonGradient,
          icon: muted ? Icons.mic_off : Icons.mic,
          iconColor: AppTheme.textInverse,
        ),
        const SizedBox(width: AppTheme.spaceLg),
        _NeonCircleButton(
          enabled: !isConnecting,
          onPressed: () => onEnd(),
          gradient: const LinearGradient(
            colors: [AppTheme.stateDanger, AppTheme.neonPink],
          ),
          icon: isConnecting ? null : Icons.call_end,
          iconColor: AppTheme.textInverse,
          child: isConnecting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textInverse,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _NeonCircleButton extends StatelessWidget {
  const _NeonCircleButton({
    required this.enabled,
    required this.gradient,
    this.icon,
    this.iconColor,
    this.child,
    required this.onPressed,
  });

  final bool enabled;
  final LinearGradient gradient;
  final IconData? icon;
  final Color? iconColor;
  final Widget? child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      tween: Tween(begin: 0.96, end: enabled ? 1.0 : 0.96),
      builder: (context, value, animatedChild) {
        return Transform.scale(
          scale: value,
          child: animatedChild,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x4400E5FF),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: child ?? Icon(icon, color: iconColor ?? AppTheme.textInverse),
            ),
          ),
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
