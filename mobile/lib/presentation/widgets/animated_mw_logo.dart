import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AnimatedMWLogo extends StatefulWidget {
  final double size;

  const AnimatedMWLogo({super.key, this.size = 32});

  @override
  State<AnimatedMWLogo> createState() => _AnimatedMWLogoState();
}

class _AnimatedMWLogoState extends State<AnimatedMWLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentState = 0; // 0 = M, 1 = transition, 2 = W

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _startCycle();
  }

  void _startCycle() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _currentState = (_currentState + 1) % 3);
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
          child: Center(
            child: _buildCurrentLetter(),
          ),
        );
      },
    );
  }

  Widget _buildCurrentLetter() {
    switch (_currentState) {
      case 0: // M
        return _buildLetter('M', AppTheme.neonBlue);
      case 1: // M ↔ W
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLetter('M', AppTheme.neonBlue, widget.size * 0.4),
            _buildArrow(),
            _buildLetter('W', AppTheme.neonPurple, widget.size * 0.4),
          ],
        );
      case 2: // W
        return _buildLetter('W', AppTheme.neonPurple);
      default:
        return _buildLetter('M', AppTheme.neonBlue);
    }
  }

  Widget _buildLetter(String letter, Color color, [double? fontSize]) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [color, color],
      ).createShader(bounds),
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? widget.size * 0.7,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.8 * _controller.value),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppTheme.neonPurple, AppTheme.neonBlue],
        ).createShader(bounds),
        child: Text(
          '↔',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

