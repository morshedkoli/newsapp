import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:newsbyte_bd/core/constants/app_constants.dart';
import 'package:newsbyte_bd/core/services/preferences_service.dart';
import 'package:newsbyte_bd/core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    // Initialize logic
    _initSplash();
  }

  void _initSplash() {
    _controller.forward();
    
    // Navigate after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Add a small delay for better UX
        Future.delayed(const Duration(milliseconds: 500), () {
           _navigateNext();
        });
      }
    });
  }

  void _navigateNext() {
    if (mounted) {
      final prefs = ref.read(preferencesServiceProvider);
      if (prefs.isFirstLaunch) {
        context.go(AppConstants.welcomeRoute);
      } else {
        context.go(AppConstants.homeRoute);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppTheme.primaryLight.withAlpha((0.5 * 255).round()),
            ],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: FadeTransition(
              opacity: _animation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/icon/newsbyte_logo.png',
                    height: 120, // Increased size for splash impact
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  // App Name
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    ).createShader(bounds),
                    child: const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 36, // Slightly larger
                        fontWeight: FontWeight.bold,
                        color: Colors.white, 
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
