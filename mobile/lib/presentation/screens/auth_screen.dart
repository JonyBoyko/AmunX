import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isRequesting = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _tokenController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _requestMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    // Для тестування: якщо email не порожній, використовуємо dev-login
    setState(() => _isRequesting = true);
    try {
      await ref.read(authProvider.notifier).devLogin(email);
      if (!mounted) return;
      // Автоматично переходимо на feed після успішного входу
      context.go('/feed');
    } catch (e) {
      _showSnack('Login failed: $e', isError: true);
      // Якщо dev-login не працює, спробуємо magic link
      try {
        final tokenHint =
            await ref.read(authProvider.notifier).requestMagicLink(email);
        if (!mounted) return;
        _showSnack('Magic link sent. Check your inbox.');
        if (tokenHint != null) {
          _tokenController.text = tokenHint;
          _showSnack('Token prefilled from dev hint.');
        }
      } catch (e2) {
        _showSnack('Request failed: $e2', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _verifyToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() => _isVerifying = true);
    try {
      await ref.read(authProvider.notifier).verifyMagicLink(token);
      if (mounted) {
        context.go('/feed');
      }
    } catch (e) {
      _showSnack('Verification failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.destructive : AppTheme.bgPopover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            left: -120,
            top: 40,
            child: Opacity(
              opacity: 0.24,
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
            right: -90,
            bottom: -60,
            child: Opacity(
              opacity: 0.18,
              child: Container(
                width: 240,
                height: 240,
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
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    tween: Tween(begin: 0.94, end: 1),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceXl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spaceSm,
                                    vertical: AppTheme.spaceXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassSurfaceLight,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusLg),
                                    border: Border.all(color: AppTheme.glassStroke),
                                  ),
                                  child: const Text(
                                    'Secure Sign-in',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceLg),
                            const Text(
                              'Sign in with magic link',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            const Text(
                              'Drop your email and we will send a one-time token. Paste it below to get started.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXl),
                                  // Glass Logo Symbol
                                  const Center(
                                    child: _GlassLogoSymbol(size: 80),
                                  ),
                                  const SizedBox(height: AppTheme.spaceMd),
                                  const Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          'Moweton',
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Voice. Async. Connected.',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            const SizedBox(height: AppTheme.spaceXl),
                            _GlassField(
                              controller: _emailController,
                              enabled: !_isRequesting,
                              hint: 'your@email.com',
                              label: 'Email',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusLg),
                                  ),
                                ),
                                onPressed:
                                    _isRequesting ? null : _requestMagicLink,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.neonGradient,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusLg),
                                    boxShadow: [
                                      ...AppTheme.glowPrimary,
                                      ...AppTheme.glowAccent,
                                    ],
                                  ),
                                  child: Center(
                                    child: _isRequesting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.textInverse,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  color: AppTheme.textInverse,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.auto_awesome,
                                                color: AppTheme.textInverse,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            // Quick test login hint
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spaceMd),
                              decoration: BoxDecoration(
                                color: AppTheme.neonBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: AppTheme.neonBlue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppTheme.neonBlue,
                                  ),
                                  const SizedBox(width: AppTheme.spaceSm),
                                  Expanded(
                                    child: Text(
                                      'Для тестування: введіть будь-який email і натисніть "Sign In"',
                                      style: TextStyle(
                                        color: AppTheme.neonBlue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXl),
                            const Text(
                              'Have a token already?',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            _GlassField(
                              controller: _tokenController,
                              enabled: !_isVerifying,
                              hint: 'Paste token=... from your email',
                              label: 'Magic token',
                              icon: Icons.lock_outline,
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.glassSurfaceLight,
                                  foregroundColor: AppTheme.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusLg),
                                    side: const BorderSide(
                                      color: AppTheme.glassStroke,
                                    ),
                                  ),
                                ),
                                onPressed:
                                    (_tokenController.text.trim().isEmpty ||
                                            _isVerifying)
                                        ? null
                                        : _verifyToken,
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Verify token'),
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
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

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
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 32,
                offset: Offset(0, 18),
                spreadRadius: -8,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.neonBlue),
        filled: true,
        fillColor: AppTheme.glassSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.glassStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.glassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(
            color: AppTheme.neonBlue,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _GlassLogoSymbol extends StatefulWidget {
  final double size;

  const _GlassLogoSymbol({this.size = 100});

  @override
  State<_GlassLogoSymbol> createState() => _GlassLogoSymbolState();
}

class _GlassLogoSymbolState extends State<_GlassLogoSymbol> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final p = _pulse.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle (purple)
              Container(
                width: widget.size * 0.6 + p * widget.size * 0.1,
                height: widget.size * 0.6 + p * widget.size * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonPurple.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.neonPurple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPurple.withValues(alpha: 0.3 * (0.6 + p * 0.4)),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Inner circle (cyan)
              Container(
                width: widget.size * 0.4 + (1 - p) * widget.size * 0.1,
                height: widget.size * 0.4 + (1 - p) * widget.size * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonBlue.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.neonBlue.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonBlue.withValues(alpha: 0.4 * (1 - p * 0.4)),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.glassSurfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: AppTheme.glassStroke,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
