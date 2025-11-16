import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/logging/app_logger.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building OnboardingScreen', tag: 'Onboarding');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0D10), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A3DEA), Color(0xFFEC4899)],
                    ),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 42),
                ),
                const SizedBox(height: AppTheme.spaceXl),
                const Text(
                  'Moweton',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                const Text(
                  'Платформа коротких голосових історій та live-подкастів.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceXl),
                const Text(
                  'Записуйте 1-хвилинні думки, виходьте в лайв,\nотримуйте реакції та будуйте комʼюніті.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      AppLogger.info('Onboarding CTA pressed', tag: 'Onboarding');
                      context.go('/auth');
                    },
                    child: const Text('Почати'),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    children: [
                      TextSpan(text: 'Продовжуючи, ви погоджуєтесь з '),
                      TextSpan(
                        text: 'Умовами',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: ' та '),
                      TextSpan(
                        text: 'Політикою.',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

