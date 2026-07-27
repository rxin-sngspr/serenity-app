import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/story/timeline/timeline_screen.dart';
import '../../features/reflect/screens/reflect_screen.dart';
import '../../features/me/screens/me_screen.dart';
import '../../features/me/screens/onboarding_screen.dart';
import '../../features/story/create/create_memory_screen.dart';
import '../../features/story/create/create_milestone_screen.dart';
import '../../features/story/timeline/screens/memory_detail_screen.dart';
import '../../features/reflect/screens/question_history_screen.dart';
import '../../features/story/timeline/calendar_screen.dart';
import '../components/serenity_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(bool isOnboarded) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isOnboarded ? '/' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/create-memory',
        name: 'create-memory',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: CreateMemoryScreen(memoryId: state.extra as int?),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
      ),
      GoRoute(
        path: '/create-milestone',
        name: 'create-milestone',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: CreateMilestoneScreen(milestoneId: state.extra as int?),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
      ),
      GoRoute(
        path: '/create-milestone/:milestoneId',
        name: 'create-milestone-edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['milestoneId'] ?? '');
          return CustomTransitionPage(
            key: state.pageKey,
            child: CreateMilestoneScreen(milestoneId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
      ),
      GoRoute(
        path: '/memory/:memoryId',
        name: 'memory-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['memoryId'] ?? '');
          return MemoryDetailScreen(memoryId: id ?? 0);
        },
      ),
      GoRoute(
        path: '/question-history',
        name: 'question-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuestionHistoryScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CalendarScreen(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const TimelineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reflect',
                name: 'reflect',
                builder: (context, state) => const ReflectScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const MeScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SerenityBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
      ),
    );
  }
}
