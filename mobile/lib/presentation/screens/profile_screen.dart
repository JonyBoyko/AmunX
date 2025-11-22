import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/user.dart';
import '../models/author_profile.dart';
import '../providers/author_directory_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/follow_button.dart';
import '../widgets/wave_tag_chip.dart';

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
  bool _loadingProfile = true;
  bool _updatingSocial = false;
  bool _neonTheme = true;
  bool _autoSummary = true;
  bool _contentFilter = false;
  String _digestSchedule = 'daily';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authorDirectoryProvider.notifier).refreshOwnProfile();
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final authorsMap = ref.watch(authorDirectoryProvider);
    final currentUserId = session.user?.id;
    final meProfile = currentUserId == null ? null : authorsMap[currentUserId];
    final followingAuthors = authorsMap.values
        .where((author) => author.isFollowed && author.id != currentUserId)
        .toList();
    final suggestedAuthors = authorsMap.values
        .where((author) => !author.isFollowed && author.id != currentUserId)
        .take(4)
        .toList();
    final postsCount = meProfile?.posts ?? 0;
    final followersCount = meProfile?.followers ?? 0;
    final followingCount = meProfile?.following ?? followingAuthors.length;

    if (_loadingProfile && meProfile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgBase,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      drawer: _ProfileDrawer(user: session.user),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            left: -120,
            top: 60,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -100,
            bottom: -80,
            child: Opacity(
              opacity: 0.16,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.bgPopover, AppTheme.neonPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceXl),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppTheme.spaceXl),
                  _buildProfileCard(meProfile, session.user),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildSocialLinks(meProfile),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildSocialStats(
                    posts: postsCount,
                    followers: followersCount,
                    following: followingCount,
                    onFollowingTap: () => _showFollowingSheet(
                      followingAuthors,
                      title: 'Following',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildTopWaveTags(),
                  if (followingAuthors.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceLg),
                    _FollowCarousel(
                      title: 'People you follow',
                      authors: followingAuthors,
                      onFollowToggle: (author) => ref
                          .read(authorDirectoryProvider.notifier)
                          .toggleFollow(author.id),
                    ),
                  ],
                  if (suggestedAuthors.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceLg),
                    _FollowCarousel(
                      title: 'Suggested for you',
                      authors: suggestedAuthors,
                      onFollowToggle: (author) => ref
                          .read(authorDirectoryProvider.notifier)
                          .toggleFollow(author.id),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceXl),
                  _buildThemeSettings(),
                  const SizedBox(height: AppTheme.spaceXl),
                  _buildAISettings(),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final currentUserId = session.user?.id;
    final authorsMap = ref.watch(authorDirectoryProvider);
    final meProfile = currentUserId == null ? null : authorsMap[currentUserId];
    final avatarUrl = meProfile?.avatarUrl;
    final avatarLabel = meProfile?.avatarEmoji ?? session.user?.email.split('@').first[0].toUpperCase() ?? 'U';

    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
            ),
            const Spacer(),
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.2),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty ? Text(avatarLabel, style: const TextStyle(fontSize: 14)) : null,
            ),
            const SizedBox(width: AppTheme.spaceMd),
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthorProfile? profile, User? user) {
    final fallbackEmail = user?.email ?? 'creator@moweton.com';
    final defaultHandle = '@${fallbackEmail.split('@').first}';
    final displayName = profile?.displayName ?? fallbackEmail.split('@').first;
    final handle = profile?.handle ?? defaultHandle;
    final bio = profile?.bio ?? 'Tell listeners what your channel is about.';
    final avatarLabel = profile?.avatarEmoji ?? (displayName.isNotEmpty ? displayName[0] : '?');
    final avatarUrl = profile?.avatarUrl;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      tween: Tween(begin: 0.92, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl?.isNotEmpty == true
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl?.isNotEmpty == true
                        ? null
                        : Text(
                            avatarLabel,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppTheme.spaceLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          handle,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                      vertical: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.neonGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: [
                        ...AppTheme.glowPrimary,
                        ...AppTheme.glowAccent,
                      ],
                    ),
                    child: const Text(
                      'Creator',
                      style: TextStyle(
                        color: AppTheme.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                bio,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLg,
                    vertical: AppTheme.spaceMd,
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
                onPressed: () => context.push('/paywall'),
                icon: const Icon(Icons.workspace_premium_outlined, color: AppTheme.textInverse),
                label: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLg,
                    vertical: AppTheme.spaceSm,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.neonGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      ...AppTheme.glowPrimary,
                      ...AppTheme.glowAccent,
                    ],
                  ),
                  child: const Text(
                    'Uplevel to Pro',
                    style: TextStyle(
                      color: AppTheme.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSocialLinks(AuthorProfile? profile) {
    final links = profile?.socialLinks ?? const {};
    return _SectionCard(
      title: 'Social links',
      action: TextButton.icon(
        onPressed: _updatingSocial ? null : () => _openSocialLinksEditor(profile),
        icon: _updatingSocial
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.edit_outlined),
        label: Text(_updatingSocial ? 'Saving...' : 'Edit'),
      ),
      child: Column(
        children: [
          for (final entry in _socialLinkPresets.asMap().entries) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(entry.value.icon, color: AppTheme.textSecondary),
              title: Text(
                links[entry.value.key] ?? 'Add ${entry.value.label}',
                style: TextStyle(
                  color: links.containsKey(entry.value.key)
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            if (entry.key != _socialLinkPresets.length - 1)
              const Divider(color: AppTheme.glassStroke),
          ],
          if (links.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppTheme.spaceSm),
              child: Text(
                'Link your Twitter, LinkedIn or website so listeners can follow along.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSocialLinksEditor(AuthorProfile? profile) async {
    final result = await _showSocialLinksEditor(profile);
    if (!mounted || result == null) {
      return;
    }
    setState(() => _updatingSocial = true);
    try {
      await ref.read(authorDirectoryProvider.notifier).updateOwnProfile(
            socialLinks: result,
          );
      _showSnack('Social links updated');
    } catch (e) {
      _showSnack('Failed to update social links');
    } finally {
      if (mounted) {
        setState(() => _updatingSocial = false);
      }
    }
  }

  Future<Map<String, String>?> _showSocialLinksEditor(
    AuthorProfile? profile,
  ) async {
    final existing = Map<String, String>.from(profile?.socialLinks ?? const {});
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final controllers = {
          for (final meta in _socialLinkPresets)
            meta.key: TextEditingController(text: existing[meta.key] ?? ''),
        };
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spaceXl,
            right: AppTheme.spaceXl,
            top: AppTheme.spaceXl,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceXl,
          ),
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit social links',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  for (final meta in _socialLinkPresets) ...[
                    TextField(
                      controller: controllers[meta.key],
                      decoration: InputDecoration(
                        labelText: meta.label,
                        hintText: meta.hint,
                        prefixIcon: Icon(meta.icon),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                  ],
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          final payload = <String, String>{};
                          controllers.forEach((key, controller) {
                            final value = controller.text.trim();
                            if (value.isNotEmpty) {
                              payload[key] = value;
                            }
                          });
                          Navigator.pop(context, payload);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildRecordingSettings() {
    return _SectionCard(
      title: 'Recording defaults',
      child: Column(
        children: [
          SwitchListTile(
            value: _publicDefault,
            activeColor: AppTheme.neonBlue,
            onChanged: (value) => setState(() => _publicDefault = value),
            title: const Text(
              'Share recordings publicly by default',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          const Divider(color: AppTheme.glassStroke),
          _SegmentControl(
            label: 'Quality',
            values: const ['Raw', 'Clean'],
            current: _quality,
            onChanged: (value) => setState(() => _quality = value),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _SegmentControl(
            label: 'Voice mask',
            values: const ['Off', 'Basic', 'Studio'],
            current: _mask,
            onChanged: (value) => setState(() => _mask = value),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings() {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: AppTheme.neonBlue, size: 20),
                const SizedBox(width: AppTheme.spaceSm),
                const Text(
                  'Налаштування теми',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.glassSurfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.glassStroke),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Neon Theme',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Яскраві неонові акценти',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _neonTheme,
                    onChanged: (value) => setState(() => _neonTheme = value),
                    activeColor: AppTheme.neonBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISettings() {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.neonPurple,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Text(
                  'AI Функції',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            // Auto Summary
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.glassSurfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.glassStroke),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto Summary',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Автоматичні TL;DR для епізодів',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoSummary,
                    onChanged: (value) => setState(() => _autoSummary = value),
                    activeColor: AppTheme.neonPurple,
                  ),
                ],
              ),
            ),
            // Content Filter
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.glassSurfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.glassStroke),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Content Filter AI',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Фільтрація небажаного контенту',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _contentFilter,
                    onChanged: (value) =>
                        setState(() => _contentFilter = value),
                    activeColor: AppTheme.neonPurple,
                  ),
                ],
              ),
            ),
            // Digest Schedule
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.glassSurfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.glassStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digest Schedule',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Частота генерації дайджестів',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Wrap(
                    spacing: AppTheme.spaceSm,
                    children: [
                      _ScheduleChip(
                        label: 'Щоденно',
                        value: 'daily',
                        selected: _digestSchedule == 'daily',
                        onTap: () => setState(() => _digestSchedule = 'daily'),
                      ),
                      _ScheduleChip(
                        label: 'Щотижнево',
                        value: 'weekly',
                        selected: _digestSchedule == 'weekly',
                        onTap: () =>
                            setState(() => _digestSchedule = 'weekly'),
                      ),
                      _ScheduleChip(
                        label: 'Вручну',
                        value: 'manual',
                        selected: _digestSchedule == 'manual',
                        onTap: () =>
                            setState(() => _digestSchedule = 'manual'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    return _SectionCard(
      title: 'Notifications',
      child: Column(
        children: [
          SwitchListTile(
            value: _notifyTopics,
            activeColor: AppTheme.neonBlue,
            onChanged: (value) => setState(() => _notifyTopics = value),
            title: const Text(
              'Trending tags & topics',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          SwitchListTile(
            value: _notifyReplies,
            activeColor: AppTheme.neonBlue,
            onChanged: (value) => setState(() => _notifyReplies = value),
            title: const Text(
              'Replies to my posts',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          SwitchListTile(
            value: _notifyDigest,
            activeColor: AppTheme.neonBlue,
            onChanged: (value) => setState(() => _notifyDigest = value),
            title: const Text(
              'AI digest updates',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          ListTile(
            onTap: () {},
            leading: const Icon(Icons.info_outline, color: AppTheme.textPrimary),
            title: const Text(
              'About Moweton',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          const Divider(color: AppTheme.glassStroke),
          ListTile(
            onTap: () => context.go('/'),
            leading: const Icon(Icons.logout, color: AppTheme.stateDanger),
            title: const Text(
              'Sign out',
              style: TextStyle(color: AppTheme.stateDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialStats({
    required int posts,
    required int followers,
    required int following,
    required VoidCallback onFollowingTap,
  }) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLg,
          vertical: AppTheme.spaceMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NeonStatCounter(
              label: 'Епізодів',
              value: posts,
              color: AppTheme.neonBlue,
            ),
            _NeonStatCounter(
              label: 'Кімнат',
              value: followers,
              color: AppTheme.neonPurple,
            ),
            GestureDetector(
              onTap: onFollowingTap,
              child: _NeonStatCounter(
                label: 'Прослухано',
                value: following,
                color: AppTheme.neonPink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopWaveTags() {
    // TODO: отримати реальні теги з профілю
    final mockTags = ['tech', 'music', 'podcast', 'design', 'ai'];
    return _SectionCard(
      title: 'Top WaveTags',
      child: WaveTagList(
        tags: mockTags,
        maxVisible: 5,
        variant: WaveTagVariant.cyan,
        size: WaveTagSize.md,
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: _GlassPanel(
            child: Padding(
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
                        backgroundImage: author.avatarUrl != null
                            ? NetworkImage(author.avatarUrl!)
                            : null,
                        child: author.avatarUrl != null
                            ? null
                            : Text(author.avatarEmoji),
                      ),
                      title: Text(
                        author.displayName,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      subtitle: Text(
                        author.handle,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
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
            ),
          ),
        );
      },
    );
  }
}
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _SectionCard({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            child,
          ],
        ),
      ),
    );
  }
}

class _NeonStatCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _NeonStatCounter({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ).createShader(bounds),
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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

class _ScheduleChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.neonBlue.withValues(alpha: 0.2)
              : AppTheme.glassSurfaceDense,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: selected ? AppTheme.neonBlue : AppTheme.glassStroke,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.neonBlue : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
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
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: authors.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceLg),
            itemBuilder: (context, index) {
              final author = authors[index];
              return SizedBox(
                width: 200,
                child: _GlassPanel(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.surfaceChip,
                              backgroundImage: author.avatarUrl != null
                                  ? NetworkImage(author.avatarUrl!)
                                  : null,
                              child: author.avatarUrl != null
                                  ? null
                                  : Text(author.avatarEmoji),
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
class _SocialLinkMeta {
  final String key;
  final String label;
  final String hint;
  final IconData icon;

  const _SocialLinkMeta({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
  });
}

const _socialLinkPresets = [
  _SocialLinkMeta(
    key: 'twitter',
    label: 'Twitter / X',
    hint: '@handle',
    icon: Icons.alternate_email,
  ),
  _SocialLinkMeta(
    key: 'linkedin',
    label: 'LinkedIn',
    hint: 'linkedin.com/in/you',
    icon: Icons.business_center,
  ),
  _SocialLinkMeta(
    key: 'website',
    label: 'Website',
    hint: 'https://your-site.com',
    icon: Icons.language,
  ),
];

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    side: const BorderSide(color: AppTheme.glassStroke),
                  ),
                  selectedColor: AppTheme.neonBlue.withValues(alpha: 0.2),
                  backgroundColor: AppTheme.glassSurfaceDense,
                  labelStyle: TextStyle(
                    color: current == value
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              )
              .toList(),
        ),
      ],
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

class _ProfileDrawer extends StatelessWidget {
  final User? user;

  const _ProfileDrawer({this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bgBase,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              decoration: BoxDecoration(
                gradient: AppTheme.neonGradient,
                boxShadow: AppTheme.glowPrimary,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.textInverse.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.textInverse, size: 32),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email.split('@').first ?? 'User',
                          style: const TextStyle(color: AppTheme.textInverse, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(color: AppTheme.textInverse.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            _DrawerItem(icon: Icons.person_outline, label: 'Profile', onTap: () => Navigator.pop(context)),
            _DrawerItem(icon: Icons.star_border, label: 'Premium', onTap: () {
              Navigator.pop(context);
              context.push('/paywall');
            }),
            _DrawerItem(icon: Icons.bookmark_border, label: 'Bookmarks', onTap: () => Navigator.pop(context)),
            _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Text('Moweton v2.0', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neonBlue),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      onTap: onTap,
      hoverColor: AppTheme.glassSurfaceLight,
    );
  }
}
