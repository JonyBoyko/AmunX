import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building OnboardingScreen', tag: 'Onboarding');

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          ),
          Positioned(
            left: -120,
            top: -80,
            child: Opacity(
              opacity: 0.28,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -100,
            child: Opacity(
              opacity: 0.18,
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
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceXl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    tween: Tween(begin: 0.9, end: 1),
                    builder: (context, value, child) {
                      final opacity = value.clamp(0.0, 1.0).toDouble();
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      );
                    },
                    child: _OnboardingGlassCard(
                      onGetStarted: () {
                        AppLogger.info('Onboarding CTA pressed', tag: 'Onboarding');
                        context.go('/auth');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingGlassCard extends StatelessWidget {
  const _OnboardingGlassCard({required this.onGetStarted});

  final VoidCallback onGetStarted;

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
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                spreadRadius: -8,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                tween: Tween(begin: 0.8, end: 1),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppTheme.neonGradient,
                    shape: BoxShape.circle,
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
              ),
              const SizedBox(height: AppTheme.spaceXl),
              const Text(
                'Async voice, on your time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              const Text(
                'Drop quick voice updates, jump into live rooms, and let smart inbox keep you in the loop.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppTheme.spaceSm,
                runSpacing: AppTheme.spaceSm,
                children: const [
                  _InfoTag(label: 'Glass UI'),
                  _InfoTag(label: 'Neon accents'),
                  _InfoTag(label: 'Live + async'),
                  _InfoTag(label: 'AI digest'),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: onGetStarted,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.neonGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: [
                        ...AppTheme.glowPrimary,
                        ...AppTheme.glowAccent,
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Get started',
                        style: TextStyle(
                          color: AppTheme.textInverse,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              const Text(
                'By continuing you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceDense,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.glassStroke),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
