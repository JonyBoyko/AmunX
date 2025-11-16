import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class CommentsScreen extends StatefulWidget {
  final String episodeId;
  final String? episodeTitle;

  const CommentsScreen({
    super.key,
    required this.episodeId,
    this.episodeTitle,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _comments = [
    {
      'author': 'Марія К.',
      'time': '5 хв',
      'text': 'Дуже цікаво! А що ти думаєш про GPT-4?',
    },
    {
      'author': 'Анонім',
      'time': '12 хв',
      'text': 'Розкажи більше про практичне застосування',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildQuickTemplates(),
            Expanded(child: _buildCommentsList()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
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
          const SizedBox(width: AppTheme.spaceSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.episodeTitle ?? 'Коментарі',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_comments.length} коментарів',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplates() {
    final templates = [
      '🤔 Питання...',
      '💬 Розкажи продовження завтра',
      '👏 Дякую за епізод!',
    ];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
        itemBuilder: (context, index) {
          final template = templates[index];
          return GestureDetector(
            onTap: () => setState(() => _controller.text = template),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgRaised,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                template,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: templates.length,
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            color: AppTheme.bgRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.brandPrimary.withOpacity(0.2),
                    child: Text(
                      comment['author']!.characters.first,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['author']!,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${comment['time']} тому',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                comment['text']!,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Row(
                children: const [
                  Text('Відповісти', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  SizedBox(width: 16),
                  Text('Репорт', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMd),
      itemCount: _comments.length,
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ваш коментар...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.bgRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          FilledButton(
            onPressed: _controller.text.isEmpty
                ? null
                : () {
                    setState(() {
                      _comments.insert(0, {
                        'author': 'Ви',
                        'time': 'щойно',
                        'text': _controller.text,
                      });
                      _controller.clear();
                    });
                  },
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
