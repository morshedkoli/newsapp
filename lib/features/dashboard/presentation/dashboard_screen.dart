import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardScreen({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Support navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.tiroBangla(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                );
              }
              return GoogleFonts.tiroBangla(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.primaryLight,
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Colors.grey.shade600),
                selectedIcon: const Icon(Icons.home_rounded, color: AppTheme.primaryColor),
                label: 'হোম',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined, color: Colors.grey.shade600),
                selectedIcon: const Icon(Icons.explore_rounded, color: AppTheme.primaryColor),
                label: 'এক্সপ্লোর',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
