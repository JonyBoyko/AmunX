import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onPressed;
  final bool dense;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onPressed,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        foregroundColor:
            isFollowing ? AppTheme.textSecondary : AppTheme.textInverse,
        backgroundColor:
            isFollowing ? Colors.transparent : AppTheme.brandPrimary,
        side: BorderSide(
          color: isFollowing ? AppTheme.surfaceBorder : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      onPressed: onPressed,
      child: Text(isFollowing ? 'Ви підписані' : 'Стежити'),
    );
  }
}
