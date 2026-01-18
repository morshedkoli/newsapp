import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/preferences_service.dart';
import '../../news/data/news_repository.dart';

import 'widgets/smart_news_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsStreamProvider);
    final prefs = ref.watch(preferencesServiceProvider);

    // One-time post-frame callback for First Launch & Resume Reading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (prefs.isFirstLaunch) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'সংক্ষিপ্ত, গুরুত্বপূর্ণ খবর এক নজরে - স্বাগতম!',
              style: GoogleFonts.hindSiliguri(color: Colors.white),
            ),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        prefs.setFirstLaunchDone();
      } else {
        // If not first launch, check if we should resume
        final lastIndex = prefs.lastReadIndex;
        if (lastIndex > 0) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'আপনি এখানে পড়া থামিয়েছিলেন - ফিরে যেতে চান?',
                style: GoogleFonts.hindSiliguri(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'চালিয়ে যান',
                textColor: Colors.amber,
                onPressed: () {
                   context.push('${AppConstants.newsReaderRoute}?index=$lastIndex');
                },
              ),
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Slightly off-white background
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppConstants.appName,
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
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
                   Icon(Icons.newspaper_outlined, size: 80, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text(
                     'এই মুহূর্তে কোনো সংবাদ নেই',
                     style: GoogleFonts.hindSiliguri(
                       fontSize: 18,
                       color: Colors.grey.shade600,
                     ),
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () => ref.read(newsRepositoryProvider).seedDummyData(),
                     icon: const Icon(Icons.refresh),
                     label: const Text('লোড ডেমো ডাটা'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.deepPurple,
                       foregroundColor: Colors.white,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                   )
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              // Trigger refresh if provider supports it, or just wait for stream update
              ref.invalidate(newsStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return SmartNewsCard(
                  news: news,
                  onTap: () {
                    context.push('${AppConstants.newsReaderRoute}?index=$index');
                  },
                );
              },
            ),
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'কিছু ভুল হয়েছে',
                style: GoogleFonts.hindSiliguri(fontSize: 18),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(newsStreamProvider),
                 child: const Text('আবার চেষ্টা করুন'),
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
             borderRadius: BorderRadius.circular(16),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
