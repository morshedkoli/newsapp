import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _tutorialData = [
    {
      'title': 'স্বাগতম ${AppConstants.appName}-তে',
      'desc': 'সংক্ষিপ্ত ও গুরুত্বপূর্ণ খবর এক নজরে।',
      'icon': 'assets/logo/full_logo.svg', // App Logo SVG
      'type': 'logo',
    },
    {
      'title': 'এক নজরে খবর',
      'desc': 'সংক্ষিপ্ত খবর পড়ুন দ্রুত। সম্পূর্ণ খবরের লিংক নিচে পাবেন।',
      'icon': 'read',
      'type': 'icon',
    },
    {
      'title': 'সহজ নেভিগেশন',
      'desc': 'উপরে বা নিচে সোয়াইপ করে পরবর্তী বা আগের সংবাদ দেখুন।',
      'icon': 'swipe',
      'type': 'icon',
    },
    {
      'title': 'নোটিফিকেশন',
      'desc': 'গুরুত্বপূর্ণ খবরের আপডেট পেতে অনুমতি দিন।',
      'icon': 'notification',
      'type': 'icon',
    },
    {
      'title': 'সংরক্ষণ করুন',
      'desc': 'সংবাদ সংরক্ষণ করুন এবং ইন্টারনেট ছাড়াও পরে পড়ুন।',
      'icon': 'save',
      'type': 'icon',
    },
  ];

  void _onFinish() async {
    // Mark tutorial as seen
    await ref.read(preferencesServiceProvider).setFirstLaunchDone();
    if (mounted) {
      context.go(AppConstants.homeRoute);
    }
  }

  void _onSkip() {
    _onFinish(); // Skip implies we are done
  }

  Future<void> _requestNotificationPermission() async {
    final prefs = ref.read(preferencesServiceProvider);
    
    // Only ask if not already asked
    if (!prefs.isPushPermissionAsked) {
      await prefs.setPushPermissionAsked(); // Flag as asked
      
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        // We don't block if they say no, just continue
      } catch (e) {
        debugPrint('Error asking permission: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    'এড়িয়ে যান',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontFamily: 'HindSiliguri', 
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _tutorialData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = _tutorialData[index];
                  return _buildPage(data);
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _tutorialData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Check if current page is Notification page (index 3 now)
                    // Data: [0:Logo, 1:Read, 2:Swipe, 3:Notification, 4:Save]
                    // If moving FROM Notification page to Save page
                    
                    if (_currentPage == 3) {
                       await _requestNotificationPermission();
                       // Then continue
                       _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else if (_currentPage == _tutorialData.length - 1) {
                      _onFinish();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == 3 
                        ? 'অনুমতি দিন' // "Allow" or "Continue" specific for notification
                        : (_currentPage == _tutorialData.length - 1
                          ? 'শুরু করুন'
                          : 'পরবর্তী'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data['type'] == 'logo')
            data['icon']!.endsWith('.svg')
                ? SvgPicture.asset(
                    data['icon']!,
                    height: 150, // Keep height mostly consistent, width auto
                  )
                : Image.asset(
                    data['icon']!,
                    height: 150,
                    width: 150,
                  )
          else
            _buildIcon(data['icon']!),
          const SizedBox(height: 40),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data['desc']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData iconData;
    switch (type) {
      case 'read':
        iconData = Icons.article_outlined;
        break;
      case 'swipe':
        iconData = Icons.swipe_vertical_outlined;
        break;
      case 'save':
        iconData = Icons.bookmark_border;
        break;
      case 'notification':
        iconData = Icons.notifications_active_outlined;
        break;
      default:
        iconData = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 80,
        color: AppTheme.primaryColor,
      ),
    );
  }
}
