import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/episode.dart';
import '../widgets/episode_card.dart';

class TopicDetailScreen extends StatelessWidget {
  final String topicId;

  const TopicDetailScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context) {
    final episodes = List.generate(
      3,
      (index) => Episode(
        id: '$topicId-$index',
        authorId: 'author',
        title: 'Думки про $topicId #${index + 1}',
        visibility: 'public',
        status: 'public',
        mask: 'none',
        quality: 'Clean',
        isLive: false,
        createdAt: DateTime.now(),
        summary: 'Короткий опис епізоду про $topicId.',
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.bgBase,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
                onPressed: () => context.pop(),
              ),
              title: Text(
                topicId,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXl),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4338CA), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topicId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Епізоди про технології, AI, розробку та інновації',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Підписатися'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {},
                                child: const Text('Поділитися'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXl),
                  ],
                ),
              ),
            ),
            SliverList.separated(
              itemCount: episodes.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppTheme.surfaceBorder,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final episode = episodes[index];
            return EpisodeCard(
              episode: episode,
              onTap: () => context.push('/episode/${episode.id}'),
            );
              },
            ),
          ],
        ),
      ),
    );
  }
}
