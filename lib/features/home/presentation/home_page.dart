import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../news/data/news_repository.dart';

import 'widgets/smart_news_card.dart';
import '../../news/presentation/news_search_delegate.dart';
import '../../ads/presentation/widgets/ad_banner_widget.dart';
import '../../ads/presentation/widgets/native_ad_widget.dart';
import '../../ads/presentation/managers/ad_manager.dart';
import '../../ads/presentation/providers/ads_provider.dart';

import '../../update/data/update_service.dart';
import '../../update/presentation/update_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Run after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOneTimeEvents();
    });
  }

  Future<void> _checkOneTimeEvents() async {
    final prefs = ref.read(preferencesServiceProvider);

    // 1. First Launch Welcome
    if (prefs.isFirstLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'সংক্ষিপ্ত, গুরুত্বপূর্ণ খবর এক নজরে - স্বাগতম!',
            style: GoogleFonts.tiroBangla(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      prefs.setFirstLaunchDone();
    } else {
       // 2. Resume Reading
       final lastIndex = prefs.lastReadIndex;
       if (lastIndex > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'আপনি এখানে পড়া থামিয়েছিলেন - ফিরে যেতে চান?',
                style: GoogleFonts.tiroBangla(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'চালিয়ে যান',
                textColor: AppTheme.primaryLight,
                onPressed: () {
                   context.push('${AppConstants.newsReaderRoute}?index=$lastIndex');
                },
              ),
            ),
          );
       }
    }

    // 3. Check for Updates
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService();
    final config = await updateService.checkUpdate();

    if (config != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !config.forceUpdate,
        builder: (context) => UpdateDialog(config: config),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icon/newsbyte_logo.png',
                height: 40,
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                ).createShader(bounds),
                child: Text(
                   AppConstants.appName,
                   style: GoogleFonts.tiroBangla(
                     fontSize: 24,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                   ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: AppTheme.primaryColor),
              onPressed: () {
                 showSearch(
                   context: context, 
                   delegate: NewsSearchDelegate(ref),
                 );
              },
            ),
          ),
        ],
      ),
      body: newsAsync.when(
        data: (newsList) {
          if (newsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.newspaper_outlined, size: 80, color: AppTheme.primaryColor.withAlpha((0.3 * 255).round())),
                   const SizedBox(height: 16),
                   Text(
                     'এই মুহূর্তে কোনো সংবাদ নেই',
                     style: GoogleFonts.tiroBangla(
                       fontSize: 18,
                       color: Colors.grey.shade600,
                     ),
                   ),
                   const SizedBox(height: 24),
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                       ),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: ElevatedButton.icon(
                       onPressed: () => ref.read(newsRepositoryProvider).seedDummyData(),
                       icon: const Icon(Icons.refresh, color: Colors.white),
                       label: const Text('লোড ডেমো ডাটা', style: TextStyle(color: Colors.white)),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.transparent,
                         shadowColor: Colors.transparent,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                       ),
                     ),
                   )
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () async {
                    // Trigger refresh if provider supports it, or just wait for stream update
                    ref.invalidate(newsStreamProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: newsList.length,
                    separatorBuilder: (context, index) {
                      // Show Native Ad after every N items (e.g., 5)
                      final adsConfig = ref.read(adsConfigProvider).valueOrNull;
                      final freq = adsConfig?.native.frequency ?? 5; // Updated to access native.frequency
                      
                      if ((index + 1) % freq == 0) {
                        return const NativeAdWidget();
                      }
                      return const SizedBox(height: 8); // Default spacing
                    },
                    itemBuilder: (context, index) {
                      final news = newsList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 0), // Separator handles spacing
                        child: SmartNewsCard(
                          news: news,
                          onTap: () async {
                            // Show Interstitial Ad before navigation
                            await ref.read(adManagerProvider).showInterstitial(context);
                            
                            if (context.mounted) {
                              context.push('${AppConstants.newsReaderRoute}?index=$index');
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const AdBannerWidget(),
            ],
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'কিছু ভুল হয়েছে',
                style: GoogleFonts.tiroBangla(fontSize: 18),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(newsStreamProvider),
                 child: Text('আবার চেষ্টা করুন', style: TextStyle(color: AppTheme.primaryColor)),
              )
            ],
          ),
        ),
        loading: () => const _NewsListSkeleton(),
      ),
    );
  }
}

class _NewsListSkeleton extends StatelessWidget {
  const _NewsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(20),
             boxShadow: [
               BoxShadow(
                 color: AppTheme.primaryColor.withAlpha((0.05 * 255).round()),
                 blurRadius: 12,
                 offset: const Offset(0, 4),
               ),
             ],
          ),
          child: Shimmer.fromColors(
            baseColor: AppTheme.primaryLight,
            highlightColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 100, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(height: 18, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 18, width: 200, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
