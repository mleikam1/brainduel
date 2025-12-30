import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/categories_screen.dart';
import 'screens/category_detail_screen.dart';
import 'screens/challenge_intro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/topic_select_screen.dart';
import 'screens/trivia_game_screen.dart';
import 'screens/trivia_result_screen.dart';
import 'theme/brain_duel_theme.dart';

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

  static const routeOnboarding = '/onboarding';
  static const routeHome = '/home';
  static const routeCategories = '/categories';
  static const routeCategoryDetail = '/categories/detail';
  static const routeTopicSelect = '/topics';
  static const routeGame = '/game';
  static const routeResults = '/results';
  static const routeProfile = '/profile';
  static const routeSettings = '/settings';

  static const nameOnboarding = 'onboarding';
  static const nameHome = 'home';
  static const nameCategories = 'categories';
  static const nameCategoryDetail = 'categoryDetail';
  static const nameTopicSelect = 'topicSelect';
  static const nameGame = 'game';
  static const nameResults = 'results';
  static const nameProfile = 'profile';
  static const nameSettings = 'settings';
  static const nameChallengeIntro = 'challengeIntro';
  static const nameQuestionFlow = 'questionFlow';

  static final GoRouter _router = GoRouter(
    initialLocation: routeOnboarding,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => routeOnboarding,
      ),
      GoRoute(
        path: routeOnboarding,
        name: nameOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: routeHome,
        name: nameHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: routeTopicSelect,
        name: nameTopicSelect,
        builder: (context, state) => const TopicSelectScreen(),
      ),
      GoRoute(
        path: routeCategories,
        name: nameCategories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: routeCategoryDetail,
        name: nameCategoryDetail,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          arguments: state.extra,
          child: const CategoryDetailScreen(),
        ),
      ),
      GoRoute(
        path: routeGame,
        name: nameGame,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          arguments: state.extra,
          child: const TriviaGameScreen(),
        ),
      ),
      GoRoute(
        path: routeResults,
        name: nameResults,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          arguments: state.extra,
          child: const TriviaResultScreen(),
        ),
      ),
      GoRoute(
        path: routeProfile,
        name: nameProfile,
        builder: (context, state) => const ProfileStatsScreen(),
      ),
      GoRoute(
        path: routeSettings,
        name: nameSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/c/:challengeId',
        name: nameChallengeIntro,
        builder: (context, state) {
          final challengeId = state.pathParameters['challengeId']!;
          return ChallengeIntroScreen(challengeId: challengeId);
        },
        routes: [
          GoRoute(
            path: 'q',
            name: nameQuestionFlow,
            pageBuilder: (context, state) {
              final challengeId = state.pathParameters['challengeId']!;
              return MaterialPage(
                key: state.pageKey,
                arguments: challengeId,
                child: const TriviaGameScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Brain Duel',
      debugShowCheckedModeBanner: false,
      theme: BrainDuelTheme.light(),
      darkTheme: BrainDuelTheme.dark(),
      routerConfig: _router,
    );
  }
}
