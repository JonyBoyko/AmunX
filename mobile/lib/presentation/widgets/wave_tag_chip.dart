import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum WaveTagVariant { cyan, purple, pink }
enum WaveTagSize { sm, md, lg }

class WaveTag extends StatelessWidget {
  final String tag;
  final WaveTagVariant variant;
  final WaveTagSize size;
  final VoidCallback? onTap;

  const WaveTag({
    super.key,
    required this.tag,
    this.variant = WaveTagVariant.cyan,
    this.size = WaveTagSize.md,
    this.onTap,
  });

  Color _getColor() {
    switch (variant) {
      case WaveTagVariant.cyan: return AppTheme.neonBlue;
      case WaveTagVariant.purple: return AppTheme.neonPurple;
      case WaveTagVariant.pink: return AppTheme.neonPink;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case WaveTagSize.sm: return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case WaveTagSize.md: return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case WaveTagSize.lg: return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getFontSize() {
    switch (size) {
      case WaveTagSize.sm: return 11;
      case WaveTagSize.md: return 13;
      case WaveTagSize.lg: return 15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final content = Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color, width: 1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      child: Text('~$tag',
        style: TextStyle(color: color, fontSize: _getFontSize(), fontWeight: FontWeight.w600),
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }
}

class WaveTagList extends StatelessWidget {
  final List<String> tags;
  final int maxVisible;
  final WaveTagVariant variant;
  final WaveTagSize size;

  const WaveTagList({super.key, required this.tags, this.maxVisible = 3,
    this.variant = WaveTagVariant.cyan, this.size = WaveTagSize.md});

  EdgeInsets _getPadding() {
    switch (size) {
      case WaveTagSize.sm: return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case WaveTagSize.md: return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case WaveTagSize.lg: return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getFontSize() {
    switch (size) {
      case WaveTagSize.sm: return 11;
      case WaveTagSize.md: return 13;
      case WaveTagSize.lg: return 15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags.take(maxVisible).toList();
    final remaining = tags.length - maxVisible;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      ...visibleTags.map((t) => WaveTag(tag: t, variant: variant, size: size)),
      if (remaining > 0)
        Container(
          padding: _getPadding(),
          decoration: BoxDecoration(
            color: AppTheme.glassSurfaceLight,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Text('+$remaining',
            style: TextStyle(color: const Color(0x99FFFFFF), fontSize: _getFontSize(), fontWeight: FontWeight.w600),
          ),
        ),
    ]);
  }
}

