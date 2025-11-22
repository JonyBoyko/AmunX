import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class QuickRecordOverlay extends StatefulWidget {
  final int duration;
  final double audioLevel;

  const QuickRecordOverlay({
    super.key,
    required this.duration,
    required this.audioLevel,
  });

  @override
  State<QuickRecordOverlay> createState() => _QuickRecordOverlayState();
}

class _QuickRecordOverlayState extends State<QuickRecordOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _animationTimer;
  final List<double> _levels = List.filled(24, 0.3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          final rng = Random();
          for (int i = 0; i < _levels.length; i++) {
            _levels[i] = 0.3 + rng.nextDouble() * (widget.audioLevel > 0 ? widget.audioLevel : 0.5);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Напівпрозорий фон з blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
              ),
            ),
            // Центральне коло з еквалайзером
            Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildRecordingCircle(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordingCircle() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Еквалайзер по колу
          CustomPaint(
            size: const Size(240, 240),
            painter: _CircularEqualizerPainter(_levels),
          ),
          // Внутрішнє коло з градієнтом
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: AppTheme.neonGradient,
              shape: BoxShape.circle,
              boxShadow: [
                ...AppTheme.glowPrimary,
                ...AppTheme.glowAccent,
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, color: AppTheme.textInverse, size: 48),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(widget.duration),
                  style: const TextStyle(
                    color: AppTheme.textInverse,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Recording...',
                  style: TextStyle(
                    color: AppTheme.textInverse,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Release to send',
                  style: TextStyle(
                    color: AppTheme.textInverse,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }
}

class _CircularEqualizerPainter extends CustomPainter {
  final List<double> levels;

  _CircularEqualizerPainter(this.levels);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 10;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [AppTheme.neonBlue, AppTheme.neonPurple],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < levels.length; i++) {
      final angle = (i / levels.length) * 2 * pi - pi / 2;
      final barHeight = 15 + levels[i] * 25;
      final innerRadius = baseRadius - barHeight;
      
      final x1 = center.dx + cos(angle - 0.05) * innerRadius;
      final y1 = center.dy + sin(angle - 0.05) * innerRadius;
      final x2 = center.dx + cos(angle + 0.05) * innerRadius;
      final y2 = center.dy + sin(angle + 0.05) * innerRadius;
      final x3 = center.dx + cos(angle + 0.05) * baseRadius;
      final y3 = center.dy + sin(angle + 0.05) * baseRadius;
      final x4 = center.dx + cos(angle - 0.05) * baseRadius;
      final y4 = center.dy + sin(angle - 0.05) * baseRadius;

      final path = Path()
        ..moveTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x3, y3)
        ..lineTo(x4, y4)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CircularEqualizerPainter oldDelegate) => true;
}


