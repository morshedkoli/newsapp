import 'package:newsbyte_bd/core/constants/app_constants.dart';

import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/explore/presentation/explore_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/news/presentation/news_reader_page.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/splash/presentation/welcome_screen.dart';

// Placeholder files will be created in the next steps, 
// using simple widgets for now to ensure compilation if I run it early.
// But mostly I will create the actual pages right after this.

final goRouter = GoRouter(
  initialLocation: AppConstants.splashRoute, // Start with Splash
  routes: [
    // Splash Route
    GoRoute(
      path: AppConstants.splashRoute,
      builder: (context, state) => const SplashScreen(),
    ),

    // Welcome / Tutorial Route
    GoRoute(
      path: AppConstants.welcomeRoute,
      builder: (context, state) => const WelcomeScreen(),
    ),

    // Shell Route for Bottom Tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return DashboardScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.homeRoute,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Tab 2: Explore
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExplorePage(),
            ),
          ],
        ),
      ],
    ),

    // Full Screen Routes (Hides Bottom Bar)
    GoRoute(
      path: AppConstants.newsReaderRoute,
      builder: (context, state) {
        final indexStr = state.uri.queryParameters['index'];
        final index = indexStr != null ? int.tryParse(indexStr) ?? 0 : 0;
        return NewsReaderPage(initialIndex: index);
      },
    ),
    
    // Deep Link Route
    // Format: /news/:newsId
    GoRoute(
      path: '/news/:newsId',
      builder: (context, state) {
        final newsId = state.pathParameters['newsId'];
        return NewsReaderPage(newsId: newsId);
      },
    ),
  ],
);
