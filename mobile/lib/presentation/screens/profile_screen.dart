import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _publicDefault = true;
  bool _notifyTopics = true;
  bool _notifyReplies = true;
  bool _notifyDigest = false;
  String _quality = 'Clean';
  String _mask = 'Off';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTheme.spaceXl),
              _buildProfileCard(),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
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
            children: const [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Text('О', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              SizedBox(width: AppTheme.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Олексій',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('@oleksiy_tech', style: TextStyle(color: Colors.white70)),
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
          title: const Text('Про додаток', style: TextStyle(color: AppTheme.textPrimary)),
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
