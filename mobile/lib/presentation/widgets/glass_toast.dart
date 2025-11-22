import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum ToastType { success, error, info, warning }

class GlassToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _GlassToastOverlay(
        message: message,
        type: type,
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }
}

class _GlassToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;

  const _GlassToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
  });

  @override
  State<_GlassToastOverlay> createState() => _GlassToastOverlayState();
}

class _GlassToastOverlayState extends State<_GlassToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppTheme.stateSuccess;
      case ToastType.error:
        return AppTheme.neonPink;
      case ToastType.warning:
        return AppTheme.stateWarning;
      case ToastType.info:
        return AppTheme.neonBlue;
    }
  }

  Color _getGlowColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppTheme.stateSuccess;
      case ToastType.error:
        return AppTheme.neonPink;
      case ToastType.warning:
        return AppTheme.stateWarning;
      case ToastType.info:
        return AppTheme.neonBlue;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppTheme.blurLg,
                  sigmaY: AppTheme.blurLg,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLg,
                    vertical: AppTheme.spaceMd,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(
                      color: _getBorderColor().withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getGlowColor().withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                      const BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIcon(),
                        color: _getBorderColor(),
                        size: 24,
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension для ScaffoldMessenger для використання скляних toast
extension GlassSnackbarExtension on ScaffoldMessengerState {
  void showGlassSnackBar(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      SnackBar(
        content: _GlassSnackBarContent(
          message: message,
          type: type,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void showGlassSuccess(String message) {
    showGlassSnackBar(message, type: ToastType.success);
  }

  void showGlassError(String message) {
    showGlassSnackBar(message, type: ToastType.error);
  }

  void showGlassInfo(String message) {
    showGlassSnackBar(message, type: ToastType.info);
  }

  void showGlassWarning(String message) {
    showGlassSnackBar(message, type: ToastType.warning);
  }
}

class _GlassSnackBarContent extends StatelessWidget {
  final String message;
  final ToastType type;

  const _GlassSnackBarContent({
    required this.message,
    required this.type,
  });

  Color _getBorderColor() {
    switch (type) {
      case ToastType.success:
        return AppTheme.stateSuccess;
      case ToastType.error:
        return AppTheme.neonPink;
      case ToastType.warning:
        return AppTheme.stateWarning;
      case ToastType.info:
        return AppTheme.neonBlue;
    }
  }

  Color _getGlowColor() {
    switch (type) {
      case ToastType.success:
        return AppTheme.stateSuccess;
      case ToastType.error:
        return AppTheme.neonPink;
      case ToastType.warning:
        return AppTheme.stateWarning;
      case ToastType.info:
        return AppTheme.neonBlue;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

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
            horizontal: AppTheme.spaceLg,
            vertical: AppTheme.spaceMd,
          ),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _getBorderColor().withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getGlowColor().withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 12),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getIcon(),
                color: _getBorderColor(),
                size: 24,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

