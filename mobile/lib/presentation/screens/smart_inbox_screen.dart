import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/i18n/l10n_extensions.dart';
import '../providers/smart_inbox_provider.dart';

class SmartInboxScreen extends ConsumerWidget {
  const SmartInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(smartInboxProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: Text(context.l10n.smartInboxTitle),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          ),
          Positioned(
            left: -80,
            top: 120,
            child: Opacity(
              opacity: 0.16,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -60,
            bottom: -40,
            child: Opacity(
              opacity: 0.12,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.bgPopover, AppTheme.neonBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          inboxAsync.when(
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
        ],
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
    final formattedDate =
        MaterialLocalizations.of(context).formatFullDate(generatedAt);
    final updatedLabel = context.l10n.smartInboxUpdated(formattedDate);
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.neonBlue),
                const SizedBox(width: AppTheme.spaceSm),
                Text(
                  context.l10n.smartInboxTrendingTitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSm,
                    vertical: AppTheme.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurfaceDense,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.glassStroke),
                  ),
                  child: Text(
                    updatedLabel,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            if (highlights.isEmpty)
              Text(
                context.l10n.smartInboxTrendingEmpty,
                style: const TextStyle(color: AppTheme.textSecondary),
              )
            else
              Wrap(
                spacing: AppTheme.spaceSm,
                runSpacing: AppTheme.spaceSm,
                children: highlights
                    .map(
                      (highlight) => Chip(
                        label: Text('#$highlight'),
                        backgroundColor:
                            AppTheme.neonBlue.withValues(alpha: 0.12),
                        labelStyle: const TextStyle(color: AppTheme.neonBlue),
                        side: const BorderSide(color: AppTheme.glassStroke),
                      ),
                    )
                    .toList(),
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.95, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceLg),
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: AppTheme.glassSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.glassStroke),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              digest.dayLabel,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            if (digest.summary.isNotEmpty)
              Text(
                digest.summary,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
              ),
            if (digest.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: digest.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor:
                            AppTheme.glassSurfaceDense.withValues(alpha: 0.9),
                        labelStyle: const TextStyle(color: AppTheme.textPrimary),
                        side: const BorderSide(color: AppTheme.glassStroke),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: AppTheme.spaceMd),
            ...digest.entries.map(
              (entry) => _InboxEntryTile(
                entry: entry,
                onOpenEpisode: onOpenEpisode,
              ),
            ),
          ],
        ),
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      tween: Tween(begin: 0.94, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: AppTheme.glassSurfaceDense,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.glassStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (entry.isNew)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.neonBlue, AppTheme.neonPink],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: AppTheme.glowPrimary,
                    ),
                    child: Text(
                      context.l10n.smartInboxNewLabel,
                      style: const TextStyle(
                        color: AppTheme.textInverse,
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
              style:
                  const TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        side: const BorderSide(color: AppTheme.glassStroke),
                        backgroundColor: AppTheme.glassSurface,
                        labelStyle: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onOpenEpisode(entry.episodeId),
                child: Text(context.l10n.smartInboxOpenEpisode),
              ),
            ),
          ],
        ),
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
        child: _GlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.smartInboxLoadFailed(message),
                  style: const TextStyle(color: AppTheme.stateDanger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.blurMd,
          sigmaY: AppTheme.blurMd,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.glassStroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 28,
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
