import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/preferences_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Max duration safeguard
    );

    // Initialize logic
    _initSplash();
  }

  void _initSplash() {
    // Navigate after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
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
      body: Center(
        child: Lottie.asset(
          'assets/animations/splash_animation.json',
          controller: _controller,
          onLoaded: (composition) {
            // Adjust duration to match Lottie file exactly
            _controller.duration = composition.duration;
            _controller.forward();
          },
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          // FrameBuilder ensures no white flash if loading takes a split second
          frameBuilder: (context, child, composition) {
            if (composition != null) {
              return child;
            } else {
              return const SizedBox(); // Invisible until loaded
            }
          },
          errorBuilder: (context, error, stackTrace) {
              // Fallback if Lottie fails
              WidgetsBinding.instance.addPostFrameCallback((_) {
                  _navigateNext();
              });
              return const SizedBox();
          },
        ),
      ),
    );
  }
}
