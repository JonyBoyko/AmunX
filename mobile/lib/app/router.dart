import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/app_logger.dart';
import '../presentation/providers/session_provider.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/auth_screen.dart';
import '../presentation/screens/feed_screen.dart';
import '../presentation/screens/explore_screen.dart';
import '../presentation/screens/recorder_screen.dart';
import '../presentation/screens/publish_screen.dart';
import '../presentation/screens/episode_detail_screen.dart';
import '../presentation/screens/comments_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/topics_screen.dart';
import '../presentation/screens/topic_detail_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/paywall_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/smart_inbox_screen.dart';
import '../presentation/screens/live_host_screen.dart';
import '../presentation/screens/live_listener_screen.dart';
import '../presentation/models/live_room.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = sessionState.isLoading;
      final isAuthenticated = sessionState.isAuthenticated;
      final location = state.uri.path;
      AppLogger.debug(
        'Router redirect check: location=$location loading=$isLoading authenticated=$isAuthenticated',
        tag: 'Router',
      );

      if (isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      if (!isAuthenticated) {
        if (location == '/onboarding' || location == '/auth') {
          return null;
        }
        return '/onboarding';
      }

      // authenticated
      if (location == '/onboarding' ||
          location == '/auth' ||
          location == '/splash') {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/recorder',
        builder: (context, state) => const RecorderScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const SmartInboxScreen(),
      ),
      GoRoute(
        path: '/publish',
        builder: (context, state) {
          final summary = state.extra is RecordingSummary
              ? state.extra as RecordingSummary
              : null;
          return PublishScreen(summary: summary);
        },
      ),
      GoRoute(
        path: '/episode/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EpisodeDetailScreen(episodeId: id);
        },
      ),
      GoRoute(
        path: '/episode/:episodeId/comments',
        builder: (context, state) {
          final episodeId = state.pathParameters['episodeId']!;
          final extra = state.extra as Map<String, Object?>?;
          final episodeTitle = extra?['title'] as String?;
          return CommentsScreen(
            episodeId: episodeId,
            episodeTitle: episodeTitle,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/topics',
        builder: (context, state) => const TopicsScreen(),
      ),
      GoRoute(
        path: '/topic/:topicId',
        builder: (context, state) {
          final topicId = Uri.decodeComponent(state.pathParameters['topicId']!);
          return TopicDetailScreen(topicId: topicId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/live/host',
        builder: (context, state) => const LiveHostScreen(),
      ),
      GoRoute(
        path: '/live/listener',
        builder: (context, state) {
          final room = state.extra is LiveRoom ? state.extra as LiveRoom : null;
          return LiveListenerScreen(room: room);
        },
      ),
    ],
  );
});
