import 'package:flutter/material.dart';
import '../../app/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                child: Text('Сповіщення', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _NotificationTile(
                    type: index % 3 == 0 ? 'like' : index % 3 == 1 ? 'follow' : 'mention',
                    author: 'User ${index + 1}',
                    time: '${index + 1}h',
                  ),
                  childCount: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String type;
  final String author;
  final String time;

  const _NotificationTile({required this.type, required this.author, required this.time});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String message;

    switch (type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = AppTheme.neonPink;
        message = 'вподобав ваш епізод';
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = AppTheme.neonBlue;
        message = 'підписався на вас';
        break;
      default:
        icon = Icons.alternate_email;
        iconColor = AppTheme.neonPurple;
        message = 'згадав вас';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(author, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


