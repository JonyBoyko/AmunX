import 'dart:math';
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
  bool _isM = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _startCycle();
  }

  void _startCycle() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isM = !_isM);
      _controller.forward(from: 0);
      _startCycle();
    });
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
            painter: _GlitchWavePainter(_controller.value, _isM),
          ),
        );
      },
    );
  }
}

class _GlitchWavePainter extends CustomPainter {
  final double animationValue;
  final bool isM;

  _GlitchWavePainter(this.animationValue, this.isM);

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
    final amplitude = size.height * 0.35;
    
    // M форма: дві вершини вгору (піки на 1/3 і 2/3)
    // W форма: дві вершини вниз (впадини на 1/3 і 2/3)
    final currentShape = isM ? animationValue : (1 - animationValue);
    
    path.moveTo(0, centerY);
    
    for (double x = 0; x <= size.width; x += 1) {
      final normalizedX = x / size.width;
      double y;
      
      if (isM) {
        // M: два піки вгору
        if (normalizedX < 0.33) {
          y = centerY - sin(normalizedX * 3 * pi) * amplitude * currentShape;
        } else if (normalizedX < 0.67) {
          y = centerY - sin((normalizedX - 0.33) * 3 * pi) * amplitude * currentShape;
        } else {
          y = centerY;
        }
      } else {
        // W: два піки вниз
        if (normalizedX < 0.33) {
          y = centerY + sin(normalizedX * 3 * pi) * amplitude * currentShape;
        } else if (normalizedX < 0.67) {
          y = centerY + sin((normalizedX - 0.33) * 3 * pi) * amplitude * currentShape;
        } else {
          y = centerY;
        }
      }
      
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlitchWavePainter oldDelegate) => 
    oldDelegate.animationValue != animationValue || oldDelegate.isM != isM;
}

