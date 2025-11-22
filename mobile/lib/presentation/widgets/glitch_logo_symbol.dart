import 'package:flutter/material.dart';

import '../../app/theme.dart';

class GlitchLogoSymbol extends StatefulWidget {
  final double size;

  const GlitchLogoSymbol({super.key, this.size = 32});

  @override
  State<GlitchLogoSymbol> createState() => _GlitchLogoSymbolState();
}

class _GlitchLogoSymbolState extends State<GlitchLogoSymbol> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4500), // 3x slower
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
          width: widget.size,
          height: widget.size,
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
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppTheme.neonPurple, AppTheme.neonBlue, AppTheme.neonPurple],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final centerY = size.height / 2;
    path.moveTo(2, centerY);

    // Плавна хвиля
    for (double x = 2; x <= size.width - 2; x += 2) {
      final wave = sin((x / size.width * 2 * 3.14159) + (animationValue * 3.14159 * 2));
      final y = centerY + wave * (size.height * 0.3);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }
  
  double sin(double value) => (value - (value * value * value / 6) + (value * value * value * value * value / 120));

  @override
  bool shouldRepaint(_GlitchWavePainter oldDelegate) => true;
}

