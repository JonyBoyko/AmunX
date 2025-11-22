import 'package:flutter/material.dart';
import '../../app/theme.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Повідомлення', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MessageTile(
                    author: 'User ${index + 1}',
                    message: 'Останнє повідомлення тут...',
                    time: '${index + 1}h',
                    unread: index % 3 == 0,
                  ),
                  childCount: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final String author;
  final String message;
  final String time;
  final bool unread;

  const _MessageTile({required this.author, required this.message, required this.time, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? AppTheme.glassSurfaceDense : AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unread ? AppTheme.neonBlue.withValues(alpha: 0.3) : AppTheme.glassStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppTheme.neonBlue.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.person, color: AppTheme.neonBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(author, style: TextStyle(color: AppTheme.textPrimary, fontWeight: unread ? FontWeight.w700 : FontWeight.w600)),
                    Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary, fontWeight: unread ? FontWeight.w500 : FontWeight.w400)),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(color: AppTheme.neonBlue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.neonBlue.withValues(alpha: 0.5), blurRadius: 6)]),
            ),
        ],
      ),
    );
  }
}


