import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../providers/smart_inbox_provider.dart';

class SmartInboxScreen extends ConsumerWidget {
  const SmartInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(smartInboxProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Smart Inbox'),
        backgroundColor: AppTheme.bgBase,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: inboxAsync.when(
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.refresh(smartInboxProvider.future),
          color: AppTheme.brandPrimary,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            children: [
              _HighlightsCard(
                highlights: state.highlights,
                generatedAt: state.generatedAt,
              ),
              const SizedBox(height: AppTheme.spaceLg),
              ...state.digests.map(
                (digest) => _DigestCard(
                  digest: digest,
                  onOpenEpisode: (episodeId) =>
                      context.push('/episode/$episodeId'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InboxError(
          message: '$error',
          onRetry: () => ref.refresh(smartInboxProvider.future),
        ),
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({
    required this.highlights,
    required this.generatedAt,
  });

  final List<String> highlights;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Що гарячого',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            if (highlights.isEmpty)
              const Text(
                'Поки затишшя. Підкинь свіжих тем або онови стрічку.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              Wrap(
                spacing: AppTheme.spaceSm,
                children: highlights
                    .map(
                      (highlight) => Chip(
                        label: Text('#$highlight'),
                        backgroundColor:
                            AppTheme.brandPrimary.withValues(alpha: 0.15),
                        labelStyle:
                            const TextStyle(color: AppTheme.brandPrimary),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Оновлено: ${MaterialLocalizations.of(context).formatFullDate(generatedAt)}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigestCard extends StatelessWidget {
  const _DigestCard({
    required this.digest,
    required this.onOpenEpisode,
  });

  final SmartInboxDigest digest;
  final ValueChanged<String> onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceLg),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                digest.dayLabel,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                children: digest.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor: AppTheme.surfaceCard,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...digest.entries.map(
            (entry) => _InboxEntryTile(
              entry: entry,
              onOpenEpisode: onOpenEpisode,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxEntryTile extends StatelessWidget {
  const _InboxEntryTile({
    required this.entry,
    required this.onOpenEpisode,
  });

  final SmartInboxEntry entry;
  final ValueChanged<String> onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.episode.title ?? 'Без назви',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (entry.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: AppTheme.brandAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.snippet,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: entry.tags
                  .map(
                    (tag) => Chip(
                      label: Text('#$tag'),
                      backgroundColor: AppTheme.bgRaised,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onOpenEpisode(entry.episode.id),
              child: const Text('Відкрити епізод'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxError extends StatelessWidget {
  const _InboxError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Smart Inbox недоступний: $message',
              style: const TextStyle(color: AppTheme.stateDanger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Спробувати ще раз'),
            ),
          ],
        ),
      ),
    );
  }
}
