import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/category_detail_screen.dart';
import 'screens/trivia_game_screen.dart';
import 'screens/trivia_result_screen.dart';
import 'screens/profile_stats_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/brain_duel_theme.dart';

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

  static const routeSplash = '/';
  static const routeHome = '/home';
  static const routeCategories = '/categories';
  static const routeCategoryDetail = '/categories/detail';
  static const routeGame = '/game';
  static const routeResults = '/results';
  static const routeProfile = '/profile';
  static const routeSettings = '/settings';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brain Duel',
      debugShowCheckedModeBanner: false,
      theme: BrainDuelTheme.light(),
      darkTheme: BrainDuelTheme.dark(),
      initialRoute: routeSplash,
      routes: {
        routeSplash: (_) => const SplashScreen(),
        routeHome: (_) => const HomeScreen(),
        routeCategories: (_) => const CategoriesScreen(),
        routeCategoryDetail: (_) => const CategoryDetailScreen(),
        routeGame: (_) => const TriviaGameScreen(),
        routeResults: (_) => const TriviaResultScreen(),
        routeProfile: (_) => const ProfileStatsScreen(),
        routeSettings: (_) => const SettingsScreen(),
      },
    );
  }
}
