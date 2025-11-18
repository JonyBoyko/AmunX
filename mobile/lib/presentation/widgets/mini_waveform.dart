import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MiniWaveform extends StatelessWidget {
  final int barCount;
  final double progress;

  const MiniWaveform({
    super.key,
    this.barCount = 32,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final rng = Random(barCount);
    final progressIndex = (barCount * progress).clamp(0, barCount).toInt();

    return SizedBox(
      height: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final height = 6 + rng.nextInt(20);
          final isPlayed = index <= progressIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: height.toDouble(),
              decoration: BoxDecoration(
                color: isPlayed
                    ? AppTheme.brandPrimary.withValues(alpha: 0.9)
                    : AppTheme.surfaceBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
          );
        }),
      ),
    );
  }
}


