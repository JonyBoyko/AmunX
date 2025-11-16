import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'recorder_screen.dart';

class PublishScreen extends StatefulWidget {
  final RecordingSummary? summary;

  const PublishScreen({
    super.key,
    this.summary,
  });

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  int _countdown = 10;
  Timer? _timer;
  String _selectedTopic = '';
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown == 0) {
        _timer?.cancel();
        context.go('/feed');
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final progress = ((10 - _countdown) / 10).clamp(0.0, 1.0);
    final topics = ['Tech', 'Life', 'Work', 'Travel', 'Health', 'Random'];

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            children: [
              _UndoToast(
                countdown: _countdown,
                progress: progress,
                onUndo: () {
                  _timer?.cancel();
                  context.pop();
                },
              ),
              const SizedBox(height: AppTheme.spaceXl * 2),
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                decoration: BoxDecoration(
                  color: AppTheme.bgRaised,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        _Badge(summary?.quality ?? 'Clean'),
                        if ((summary?.mask ?? 'Off') != 'Off')
                          _Badge('Mask: ${summary?.mask}'),
                        _Badge(summary?.isPublic ?? true ? 'Публічно' : 'Приватно'),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Заголовок (необов’язково)',
                        filled: true,
                        fillColor: AppTheme.bgPopover,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    const Text(
                      'Тема',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Wrap(
                      spacing: 8,
                      children: topics
                          .map(
                            (topic) => ChoiceChip(
                              label: Text(topic),
                              selected: _selectedTopic == topic,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedTopic = topic);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              const Text(
                'Після публікації епізод з’явиться у стрічці.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UndoToast extends StatelessWidget {
  final int countdown;
  final double progress;
  final VoidCallback onUndo;

  const _UndoToast({
    required this.countdown,
    required this.progress,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            color: AppTheme.brandPrimary,
            backgroundColor: AppTheme.surfaceBorder,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Публікуємо за $countdown с',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              OutlinedButton(
                onPressed: onUndo,
                child: const Text('Скасувати'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceChip,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}

