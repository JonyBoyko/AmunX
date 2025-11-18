import 'dart:async';

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
    setState(() => _isRequesting = true);
    try {
      final tokenHint =
          await ref.read(authProvider.notifier).requestMagicLink(email);
      if (!mounted) return;
      _showSnack('Ми надіслали посилання на ');
      if (tokenHint != null) {
        _tokenController.text = tokenHint;
        _showSnack('Токен для дев-режиму автозаповнено');
      }
    } catch (e) {
      _showSnack('Помилка: ', isError: true);
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
      _showSnack('Помилка входу: ', isError: true);
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
        backgroundColor: isError ? AppTheme.stateDanger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Укажи email',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ми надішлемо Magic Link на твою пошту.',
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
                  enabled: !_isRequesting,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isRequesting ? null : _requestMagicLink,
                    child: _isRequesting
                        ? const CircularProgressIndicator(
                            color: AppTheme.textInverse,
                          )
                        : const Text('Надіслати посилання'),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXl),
                const Text(
                  'Вже маєш токен?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                TextField(
                  controller: _tokenController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Встав token=... із листа',
                    filled: true,
                    fillColor: AppTheme.bgRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  enabled: !_isVerifying,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.tonal(
                    onPressed:
                        (_tokenController.text.trim().isEmpty || _isVerifying)
                            ? null
                            : _verifyToken,
                    child: _isVerifying
                        ? const CircularProgressIndicator()
                        : const Text('Підтвердити токен'),
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
