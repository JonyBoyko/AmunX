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
    this.barCount = 32,
    this.progress = 0.0,
    this.isLive = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final rng = Random(barCount);
    final progressIndex = (barCount * progress).clamp(0, barCount).toInt();

    // Для live режиму використовуємо анімацію
    final effectiveProgress = isLive ? null : progressIndex;

    return SizedBox(
      height: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: List.generate(barCount, (index) {
          final height = 6 + rng.nextInt(20);
          final isPlayed = effectiveProgress != null && index <= effectiveProgress;
          final isActive = isLive || (isPlaying && isPlayed);

          // Для live режиму використовуємо випадкову анімацію
          final liveHeight = isLive
              ? (6 + (rng.nextInt(20) + (DateTime.now().millisecond % 20))).toDouble()
              : height.toDouble();

          return Expanded(
            child: AnimatedContainer(
              duration: Duration(
                milliseconds: isLive ? 200 + (index % 3) * 50 : 300,
              ),
              curve: isLive ? Curves.easeInOut : Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: isLive ? liveHeight : height.toDouble(),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isLive
                            ? [
                                AppTheme.neonPink.withValues(alpha: 0.8),
                                AppTheme.neonBlue.withValues(alpha: 0.9),
                              ]
                            : [
                                AppTheme.neonBlue.withValues(alpha: 0.9),
                                AppTheme.neonBlue.withValues(alpha: 0.6),
                              ],
                      )
                    : null,
                color: isActive ? null : AppTheme.glassStroke,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                boxShadow: isActive && isLive
                    ? [
                        BoxShadow(
                          color: AppTheme.neonPink.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: AppTheme.neonBlue.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.neonBlue.withValues(alpha: 0.2),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}


