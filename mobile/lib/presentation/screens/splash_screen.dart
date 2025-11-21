import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.info('Splash screen shown', tag: 'Splash');
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building splash screen', tag: 'Splash');

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            top: -80,
            left: -60,
            child: Opacity(
              opacity: 0.28,
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
            bottom: -100,
            right: -80,
            child: Opacity(
              opacity: 0.18,
              child: Container(
                width: 260,
                height: 260,
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
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0.85, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: const _SplashBadge(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBadge extends StatelessWidget {
  const _SplashBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.blurLg,
          sigmaY: AppTheme.blurLg,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceXl,
            vertical: AppTheme.spaceLg,
          ),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 30,
                offset: Offset(0, 16),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                  boxShadow: [
                    ...AppTheme.glowPrimary,
                    ...AppTheme.glowAccent,
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppTheme.textInverse,
                  size: 42,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              const Text(
                'Moweton',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              const Text(
                'Async voice, live rooms, AI digest.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              const SizedBox(
                width: 64,
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: AppTheme.glassSurfaceLight,
                  color: AppTheme.neonBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
