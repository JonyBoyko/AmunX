import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class LiveListenerScreen extends StatelessWidget {
  const LiveListenerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  children: [
                    _buildHostCard(),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildTranscriptPreview(),
                    const SizedBox(height: AppTheme.spaceXl),
                    _buildReactions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.stateDanger,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(color: AppTheme.textInverse, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white24,
            child: Text('О', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          const SizedBox(width: AppTheme.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Олексій в ефірі',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Live про AI та розробку',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptPreview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Live Translate',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Привіт! Сьогодні говоримо про останні оновлення...',
            style: TextStyle(color: AppTheme.textPrimary, height: 1.4),
          ),
          SizedBox(height: 12),
          Divider(color: AppTheme.surfaceBorder),
          SizedBox(height: 12),
          Text(
            'Hello! Today we\'re talking about the latest updates...',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    final reactions = ['👍', '🔥', '💡', '❤️', '👏'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Реакції',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Wrap(
          spacing: 12,
          children: reactions
              .map(
                (emoji) => GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.bgRaised,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

