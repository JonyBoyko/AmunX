import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../models/author_profile.dart';
import '../providers/author_directory_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/follow_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _publicDefault = true;
  bool _notifyTopics = true;
  bool _notifyReplies = true;
  bool _notifyDigest = false;
  String _quality = 'Clean';
  String _mask = 'Off';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final authorsMap = ref.watch(authorDirectoryProvider);
    final followingAuthors =
        authorsMap.values.where((author) => author.isFollowed).toList();
    final suggestedAuthors = authorsMap.values
        .where((author) => !author.isFollowed)
        .take(4)
        .toList();
    final postsCount = 12 + (followingAuthors.length * 3);
    final followersCount = 180 + followingAuthors.length * 9;

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTheme.spaceXl),
              _buildProfileCard(session.user),
              const SizedBox(height: AppTheme.spaceLg),
              _buildSocialStats(
                posts: postsCount,
                followers: followersCount,
                following: followingAuthors.length,
                onFollowingTap: () => _showFollowingSheet(followingAuthors,
                    title: 'Ваші підписки'),
              ),
              if (followingAuthors.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceLg),
                _FollowCarousel(
                  title: 'Ви слухаєте',
                  authors: followingAuthors,
                  onFollowToggle: (author) => ref
                      .read(authorDirectoryProvider.notifier)
                      .toggleFollow(author.id),
                ),
              ],
              if (suggestedAuthors.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceLg),
                _FollowCarousel(
                  title: 'Кого ще послухати',
                  authors: suggestedAuthors,
                  onFollowToggle: (author) => ref
                      .read(authorDirectoryProvider.notifier)
                      .toggleFollow(author.id),
                ),
              ],
              const SizedBox(height: AppTheme.spaceXl),
              _buildRecordingSettings(),
              const SizedBox(height: AppTheme.spaceXl),
              _buildNotifications(),
              const SizedBox(height: AppTheme.spaceXl),
              _buildActions(context),
              const SizedBox(height: AppTheme.spaceXl),
              const Text(
                'Moweton v1.0.0',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon:
              const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon:
              const Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildProfileCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Text('М',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              const SizedBox(width: AppTheme.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.email.split('@').first.toUpperCase() ??
                          'Moweton Creator',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${(user?.email ?? 'creator@moweton.com').split('@').first}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => context.push('/paywall'),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Оновити до Pro'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSettings() {
    return _SectionCard(
      title: 'Налаштування запису',
      child: Column(
        children: [
          SwitchListTile(
            value: _publicDefault,
            onChanged: (value) => setState(() => _publicDefault = value),
            title: const Text('Публічно за замовчуванням'),
          ),
          const Divider(color: AppTheme.surfaceBorder),
          _SegmentControl(
            label: 'Якість',
            values: const ['Raw', 'Clean'],
            current: _quality,
            onChanged: (value) => setState(() => _quality = value),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _SegmentControl(
            label: 'Маскування',
            values: const ['Off', 'Basic', 'Studio'],
            current: _mask,
            onChanged: (value) => setState(() => _mask = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return _SectionCard(
      title: 'Нотифікації',
      child: Column(
        children: [
          SwitchListTile(
            value: _notifyTopics,
            onChanged: (value) => setState(() => _notifyTopics = value),
            title: const Text('Нові епізоди в темах'),
          ),
          SwitchListTile(
            value: _notifyReplies,
            onChanged: (value) => setState(() => _notifyReplies = value),
            title: const Text('Відповіді на епізоди'),
          ),
          SwitchListTile(
            value: _notifyDigest,
            onChanged: (value) => setState(() => _notifyDigest = value),
            title: const Text('Денний дайджест'),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: () {},
          leading: const Icon(Icons.info_outline, color: AppTheme.textPrimary),
          title: const Text('Про додаток',
              style: TextStyle(color: AppTheme.textPrimary)),
        ),
        ListTile(
          onTap: () => context.go('/'),
          leading: const Icon(Icons.logout, color: AppTheme.stateDanger),
          title: const Text(
            'Вийти',
            style: TextStyle(color: AppTheme.stateDanger),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialStats({
    required int posts,
    required int followers,
    required int following,
    required VoidCallback onFollowingTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCounter(label: 'Пости', value: posts),
          _StatCounter(label: 'Підписники', value: followers),
          GestureDetector(
            onTap: onFollowingTap,
            child: _StatCounter(label: 'Підписки', value: following),
          ),
        ],
      ),
    );
  }

  Future<void> _showFollowingSheet(
    List<AuthorProfile> authors, {
    required String title,
  }) async {
    if (authors.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              ...authors.map(
                (author) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.surfaceChip,
                    child: Text(author.avatarEmoji),
                  ),
                  title: Text(
                    author.displayName,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(author.handle,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  trailing: FollowButton(
                    isFollowing: author.isFollowed,
                    onPressed: () => setState(() {
                      ref
                          .read(authorDirectoryProvider.notifier)
                          .toggleFollow(author.id);
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          child,
        ],
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  final String label;
  final int value;

  const _StatCounter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _FollowCarousel extends StatelessWidget {
  final String title;
  final List<AuthorProfile> authors;
  final ValueChanged<AuthorProfile> onFollowToggle;

  const _FollowCarousel({
    required this.title,
    required this.authors,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: authors.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spaceLg),
            itemBuilder: (context, index) {
              final author = authors[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                decoration: BoxDecoration(
                  color: AppTheme.bgRaised,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.surfaceChip,
                          child: Text(author.avatarEmoji),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author.displayName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                author.handle,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Expanded(
                      child: Text(
                        author.bio,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    FollowButton(
                      isFollowing: author.isFollowed,
                      onPressed: () => onFollowToggle(author),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SegmentControl extends StatelessWidget {
  final String label;
  final List<String> values;
  final String current;
  final ValueChanged<String> onChanged;

  const _SegmentControl({
    required this.label,
    required this.values,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: current == value,
                  onSelected: (selected) {
                    if (selected) onChanged(value);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
