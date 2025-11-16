import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = [
      {'title': 'Tech', 'emoji': '💻', 'description': 'AI, розробка, інновації'},
      {'title': 'Life', 'emoji': '🌿', 'description': 'Ранкові рефлексії та звички'},
      {'title': 'Health', 'emoji': '🏃', 'description': 'Спорт і ментальне здоров’я'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          itemCount: topics.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceLg),
          itemBuilder: (context, index) {
            final topic = topics[index];
            return GestureDetector(
              onTap: () => context.push('/topic/${Uri.encodeComponent(topic['title']!)}'),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3730A3), Color(0xFF9333EA)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Row(
                  children: [
                    Text(
                      topic['emoji']!,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: AppTheme.spaceLg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topic['description']!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
