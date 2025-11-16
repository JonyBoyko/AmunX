import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final normalizedEmail = email.toLowerCase();

    setState(() => _isLoading = true);
    AppLogger.info('Auth request started for $normalizedEmail', tag: 'AuthUI');

    unawaited(
      ref.read(authProvider.notifier).requestMagicLink(email).catchError(
        (e, stackTrace) {
          AppLogger.error(
            'Magic link request failed for $normalizedEmail',
            tag: 'AuthUI',
            error: e,
            stackTrace: stackTrace,
          );
        },
      ),
    );

    await _completeLogin(normalizedEmail);
  }

  Future<void> _completeLogin(String normalizedEmail) async {
    AppLogger.warning('Auto-login enabled for $normalizedEmail', tag: 'AuthUI');
    await ref.read(sessionProvider.notifier).setToken('dev-token-$normalizedEmail');
    if (mounted) {
      context.go('/feed');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building AuthScreen', tag: 'AuthUI');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0D10), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                const Text(
                  'Вкажіть email',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ми надішлемо Magic Link для входу.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spaceXl),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'you@email.com',
                    filled: true,
                    fillColor: AppTheme.bgRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _requestMagicLink,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: AppTheme.textInverse)
                        : const Text('Надіслати лінк'),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

