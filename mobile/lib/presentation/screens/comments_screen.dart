import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/models/comment.dart';
import '../providers/comments_provider.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({
    super.key,
    required this.episodeId,
    this.episodeTitle,
  });

  final String episodeId;
  final String? episodeTitle;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider(widget.episodeId));
    final comments = commentsState.asData?.value ?? const <Comment>[];

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: widget.episodeTitle ?? 'Replies',
              total: comments.length,
            ),
            _QuickTemplates(
              onSelect: (value) {
                setState(() {
                  _controller.text = value;
                });
              },
            ),
            Expanded(
              child: commentsState.when(
                data: _CommentsList.new,
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, __) => _CommentsError(
                  message: error.toString(),
                  onRetry: () => ref
                      .read(commentsProvider(widget.episodeId).notifier)
                      .refresh(),
                ),
              ),
            ),
            _InputBar(
              controller: _controller,
              isSubmitting: _isSubmitting,
              onSubmit: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(commentsProvider(widget.episodeId).notifier).submit(text);
      _controller.clear();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post reply: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.total});

  final String title;
  final int total;

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$total comments',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTemplates extends StatelessWidget {
  const _QuickTemplates({required this.onSelect});

  final ValueChanged<String> onSelect;

  static const _templates = <String>[
    'Great insight! Quick thoughtвЂ¦',
    'Should we clip this for the wider team?',
    'Can you expand on that idea?',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
        itemBuilder: (context, index) {
          final template = _templates[index];
          return GestureDetector(
            onTap: () => onSelect(template),
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
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSm),
        itemCount: _templates.length,
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList(List<Comment> comments) : _comments = comments;

  final List<Comment> _comments;

  @override
  Widget build(BuildContext context) {
    if (_comments.isEmpty) {
      return const Center(
        child: Text(
          'No replies yet. Be the first to add one.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMd),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final formatter = DateFormat('MMM d HH:mm');
        final timestamp = formatter.format(comment.createdAt);
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            color: AppTheme.bgRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                comment.text,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final disabled = controller.text.trim().isEmpty || isSubmitting;
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
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Share your replyвЂ¦',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.bgRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          FilledButton(
            onPressed: disabled ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _CommentsError extends StatelessWidget {
  const _CommentsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(color: AppTheme.stateDanger),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
