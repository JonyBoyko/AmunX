import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_provider.dart';
import '../services/push_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PushSettingsCard(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Sign Out'),
              leading: const Icon(Icons.logout),
              onTap: () async {
                await ref.read(sessionProvider.notifier).clearSession();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PushSettingsCard extends ConsumerWidget {
  const _PushSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushState = ref.watch(pushStatusProvider);
    final pushService = ref.read(pushServiceProvider);
    final permission =
        pushState.settings?.authorizationStatus ?? AuthorizationStatus.notDetermined;
    final permissionLabel = _permissionLabel(permission);
    final backendLabel =
        pushState.backendRegistered ? 'Registered' : 'Not registered';
    final tokenPreview = pushState.firebaseToken?.isNotEmpty == true
        ? '${pushState.firebaseToken!.substring(0, 8)}…'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Push notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Permission: $permissionLabel',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Backend: $backendLabel',
              style: const TextStyle(color: Colors.white70),
            ),
            if (tokenPreview != null)
              Text(
                'FCM: $tokenPreview',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            if (pushState.isRegistering) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Registering…'),
                ],
              ),
            ],
            if (pushState.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last error: ${pushState.lastError}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => pushService.refreshPermissions(),
                  child: const Text('Refresh status'),
                ),
                FilledButton(
                  onPressed: pushState.permissionGranted
                      ? null
                      : () => pushService.requestUserPermission(),
                  child: const Text('Enable push'),
                ),
                TextButton(
                  onPressed: () => pushService.openSystemSettings(),
                  child: const Text('Open system settings'),
                ),
                OutlinedButton(
                  onPressed: () => pushService.reRegisterDevice(),
                  child: const Text('Re-register device'),
                ),
                if (pushState.backendRegistered)
                  TextButton(
                    onPressed: () => pushService.unregisterDevice(),
                    child: const Text('Unregister device'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _permissionLabel(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Granted';
      case AuthorizationStatus.provisional:
        return 'Provisional';
      case AuthorizationStatus.denied:
        return 'Denied';
      case AuthorizationStatus.notDetermined:
        return 'Not determined';
    }
  }
}

