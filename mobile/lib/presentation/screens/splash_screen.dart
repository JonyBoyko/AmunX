import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Splash screen shown', tag: 'Splash');
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building splash screen', tag: 'Splash');

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          // Animated orbs with blur
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: MediaQuery.of(context).size.width * 0.25,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value * 0.3,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 384,
                      height: 384,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.neonBlue,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonBlue.withValues(alpha: 0.5),
                            blurRadius: 140,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            right: MediaQuery.of(context).size.width * 0.25,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value * 0.3,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 384,
                      height: 384,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.neonPurple,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonPurple.withValues(alpha: 0.5),
                            blurRadius: 140,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

class _SplashBadge extends StatefulWidget {
  const _SplashBadge();

  @override
  State<_SplashBadge> createState() => _SplashBadgeState();
}

class _SplashBadgeState extends State<_SplashBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _sparkleController;
  late Animation<double> _sparkleRotation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _sparkleRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sparkles decoration
        Positioned(
          top: -16,
          right: -16,
          child: AnimatedBuilder(
            animation: _sparkleRotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _sparkleRotation.value * 2 * 3.14159,
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.neonPurple,
                  size: 24,
                ),
              );
            },
          ),
        ),
        ClipRRect(
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
                border: Border.all(
                  color: AppTheme.neonBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                  const BoxShadow(
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
                  // Glitch Logo Symbol (звукова хвиля)
                  const _GlitchLogoSymbol(),
                  const SizedBox(height: AppTheme.spaceLg),
                  const Text(
                    'Moweton',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  const Text(
                    'Voice. Async. Connected.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXl),
                  // Loading indicator with dots
                  _LoadingDots(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_controller.value + delay) % 1.0;
            final scale = 1.0 + (0.5 * (1 - (animationValue * 2 - 1).abs()));
            final opacity = 0.3 + (0.7 * (1 - (animationValue * 2 - 1).abs()));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.neonBlue,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonBlue.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _GlitchLogoSymbol extends StatefulWidget {
  const _GlitchLogoSymbol();

  @override
  State<_GlitchLogoSymbol> createState() => _GlitchLogoSymbolState();
}

class _GlitchLogoSymbolState extends State<_GlitchLogoSymbol> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _GlitchWavePainter(_controller.value),
          ),
        );
      },
    );
  }
}

class _GlitchWavePainter extends CustomPainter {
  final double animationValue;

  _GlitchWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppTheme.neonPurple, AppTheme.neonBlue, AppTheme.neonPurple],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Анімована звукова хвиля
    final path = Path();
    final centerY = size.height / 2;
    path.moveTo(20, centerY);

    for (double x = 20; x <= size.width - 20; x += 10) {
      final wave = ((x / 10 + animationValue * 10) % 2) - 1;
      final y = centerY + wave * 20;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Аудіо бари знизу
    final barPaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppTheme.neonPurple, AppTheme.neonBlue],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < 5; i++) {
      final x = 30.0 + i * 15;
      final barHeight = 5 + ((animationValue + i * 0.2) % 1.0) * 10;
      canvas.drawLine(
        Offset(x, size.height - 20),
        Offset(x, size.height - 20 - barHeight),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlitchWavePainter oldDelegate) => true;
}
