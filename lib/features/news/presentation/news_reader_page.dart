import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/preferences_service.dart';
import '../../news/data/news_repository.dart';
import '../../news/domain/news_model.dart'; // Copied
import 'widgets/news_detail_view.dart';

class NewsReaderPage extends ConsumerStatefulWidget {
  final int initialIndex;
  final String? newsId; // For Deep Links

  const NewsReaderPage({
    super.key,
    this.initialIndex = 0,
    this.newsId,
  });

  @override
  ConsumerState<NewsReaderPage> createState() => _NewsReaderPageState();
}

class _NewsReaderPageState extends ConsumerState<NewsReaderPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  DateTime _lastSwipeTime = DateTime.fromMillisecondsSinceEpoch(0);
  
  // New: Accumulator for overscroll sensitivity
  double _overscrollAccumulator = 0.0;
  static const double _kSwipeThreshold = 80.0; // Require 80 logical pixels of drag

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (DateTime.now().difference(_lastSwipeTime) < const Duration(milliseconds: 500)) return;
    _lastSwipeTime = DateTime.now();

    if (_currentIndex < (ref.read(newsStreamProvider).value?.length ?? 0) - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      HapticFeedback.lightImpact(); 
    }
  }

  void _previousPage() {
    if (DateTime.now().difference(_lastSwipeTime) < const Duration(milliseconds: 500)) return;
    _lastSwipeTime = DateTime.now();

    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      HapticFeedback.lightImpact(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.newsId != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<NewsModel?>(
          future: ref.read(newsRepositoryProvider).getNewsById(widget.newsId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('সংবাদটি পাওয়া যায়নি')),
                   );
                   context.go(AppConstants.homeRoute);
                 }
               });
               return const Center(child: CircularProgressIndicator());
            }
            final news = snapshot.data!;
            return _buildNewsDetail(context, ref, news, isSingle: true);
          },
        ),
      );
    }

    final newsAsync = ref.watch(newsStreamProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: newsAsync.when(
        data: (newsList) {
          if (newsList.isEmpty) return const Center(child: Text('No news', style: TextStyle(color: Colors.white)));
          
          return Stack(
            children: [
              ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  physics: const NeverScrollableScrollPhysics(), 
                  controller: _pageController,
                  onPageChanged: (index) {
                     setState(() {
                       _currentIndex = index;
                       _overscrollAccumulator = 0.0; // Reset
                     });
                     ref.read(preferencesServiceProvider).setLastReadIndex(index);
                  },
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    return _buildNewsDetail(
                      context, 
                      ref, 
                      newsList[index],
                      onInnerScrollNotification: (notification) {
                         // Reset accumulator on new drag start or direction switch
                         if (notification is ScrollStartNotification) {
                             if (notification.dragDetails != null) {
                                // User started dragging
                                _overscrollAccumulator = 0.0;
                             }
                         }

                         // Robust Logic with Threshold
                         if (notification is OverscrollNotification) {
                           _overscrollAccumulator += notification.overscroll;
                           
                           if (_overscrollAccumulator < -_kSwipeThreshold) {
                             // Dragged Down (to see Previous) significantly
                             _previousPage();
                             _overscrollAccumulator = 0.0; // Reset after trigger
                           } else if (_overscrollAccumulator > _kSwipeThreshold) {
                             // Dragged Up (to see Next) significantly
                             _nextPage();
                             _overscrollAccumulator = 0.0; // Reset after trigger
                           }
                         }
                         
                         // Clean reset if user lifts finger without triggering
                         if (notification is ScrollEndNotification) {
                           _overscrollAccumulator = 0.0;
                         }

                         return false; 
                      },
                    );
                  },
                ),
              ),
              
              // Swipe Tutorial
              _buildSwipeTutorial(ref),

              // Bottom Navigation Controls
              Positioned(
                bottom: 30, // Above Safe Area
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         // Previous
                         IconButton(
                           onPressed: _currentIndex > 0 ? _previousPage : null,
                           icon: Icon(
                             Icons.keyboard_arrow_up, 
                             color: _currentIndex > 0 ? Colors.white : Colors.grey,
                             size: 32,
                           ),
                           tooltip: 'Previous',
                         ),
                         Container(width: 1, height: 24, color: Colors.white24),
                         // Next
                         IconButton(
                           onPressed: _currentIndex < newsList.length - 1 ? _nextPage : null,
                           icon: Icon(
                             Icons.keyboard_arrow_down,
                             color: _currentIndex < newsList.length - 1 ? Colors.white : Colors.grey,
                             size: 32,
                           ),
                           tooltip: 'Next',
                         ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildSwipeTutorial(WidgetRef ref) {
      return Consumer(
        builder: (context, ref, child) {
          final prefs = ref.watch(preferencesServiceProvider);
          if (prefs.isSwipeTutorialShown) return const SizedBox.shrink();
          
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(seconds: 4));
            prefs.setSwipeTutorialShown();
          });

          return Positioned(
            bottom: 120,
            right: 20,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.7 * 255).round()),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      const Icon(Icons.keyboard_double_arrow_up, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'সোয়াইপ করে পড়ুন',
                        style: GoogleFonts.hindSiliguri(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }

  Widget _buildNewsDetail(
    BuildContext context, 
    WidgetRef ref, 
    NewsModel news, 
    {
      bool isSingle = false,
      bool Function(ScrollNotification)? onInnerScrollNotification,
    }
  ) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: onInnerScrollNotification,
          child: NewsDetailView(
            newsId: news.id,
            title: news.title,
            imageUrl: news.imageUrl,
            summary: news.summary,
            onReadMore: () {
                ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening full article...')),
              );
            },
            onShare: () {
              HapticFeedback.lightImpact(); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing...')),
              );
            },
          ),
        ),
        if (isSingle)
           Positioned(
             top: 40,
             left: 16,
             child: CircleAvatar(
               backgroundColor: Colors.black.withAlpha((0.5 * 255).round()),
               child: IconButton(
                 icon: const Icon(Icons.arrow_back, color: Colors.white),
                 onPressed: () => context.go(AppConstants.homeRoute), 
               ),
             ),
           ),
      ],
    );
  }
}
