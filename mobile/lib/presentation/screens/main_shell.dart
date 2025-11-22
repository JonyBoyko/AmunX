import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/bottom_nav_bar.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import 'live_host_screen.dart';

final currentNavTabProvider = StateProvider<NavTab>((ref) => NavTab.feed);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(currentNavTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: activeTab.index,
        children: const [
          FeedScreen(), // Головна
          LiveHostScreen(), // Circle
          SearchScreen(), // Пошук
          NotificationsScreen(),
          MessagesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        activeTab: activeTab,
        onTabSelected: (tab) => ref.read(currentNavTabProvider.notifier).state = tab,
      ),
    );
  }
}

