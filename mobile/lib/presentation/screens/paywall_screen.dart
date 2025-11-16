import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      ['🌍', 'Real-time captions & dubbing', 'Автоматичний переклад live на будь-яку мову'],
      ['📝', 'Повні транскрипти та розділи', 'Текстова версія всіх епізодів'],
      ['🎙️', 'Studio voice mask', 'Покращене маскування голосу'],
      ['⏱️', 'Довші Live епізоди', 'До 60 хвилин замість 10'],
      ['📊', 'Розширена аналітика', 'Детальна статистика прослуховувань'],
      ['🎯', 'Пріоритетна підтримка', 'Швидка відповідь від команди'],
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A3DEA), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(Icons.workspace_premium, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  const Text(
                    'Оновіться до Pro',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Отримайте всі можливості WalkCast',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXl),
              ...features.map(
                (feature) => Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  decoration: BoxDecoration(
                    color: AppTheme.bgRaised,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Row(
                    children: [
                      Text(feature[0], style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature[1],
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              feature[2],
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), Color(0xFFBE185D)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          '₴199',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '/місяць',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    const _FeatureLine('Перші 7 днів безкоштовно'),
                    const _FeatureLine('Скасувати можна будь-коли'),
                    const _FeatureLine('Всі майбутні функції включені'),
                    const SizedBox(height: AppTheme.spaceLg),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {},
                      child: const Text('Почати безкоштовний період'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Переглянути демо можливостей',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              const Text(
                'Підписка автоматично продовжується. Скасувати можна в будь-який час.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;

  const _FeatureLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.stateSuccess, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

