import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MiniWaveform extends StatelessWidget {
  final int barCount;
  final double progress;
  final bool isLive;
  final bool isPlaying;

  const MiniWaveform({
    super.key,
    this.barCount = 120,
    this.progress = 0.0,
    this.isLive = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final rng = Random(barCount);
    final progressIndex = (barCount * progress).clamp(0, barCount).toInt();

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: List.generate(barCount, (index) {
          final height = 10 + rng.nextInt(35);
          final isPlayed = index <= progressIndex;
          
          // Темніший колір у звичайному стані, світліший при програванні
          final playedColor = isPlaying
            ? (isLive ? AppTheme.neonPink : AppTheme.neonBlue)
            : (isLive ? AppTheme.neonPink.withValues(alpha: 0.5) : AppTheme.neonBlue.withValues(alpha: 0.6));
          
          final unplayedColor = AppTheme.glassStroke.withValues(alpha: 0.3);
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.25),
              height: height.toDouble(),
              decoration: BoxDecoration(
                color: isPlayed ? playedColor : unplayedColor,
                borderRadius: BorderRadius.circular(0.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}


