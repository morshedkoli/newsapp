import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';

import '../../home/presentation/widgets/smart_news_card.dart';
import '../../news/data/news_repository.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  String _selectedCategory = 'সব'; // Default 'All'

  final List<String> _categories = [
    'সব',
    'রাজনীতি',
    'অর্থনীতি',
    'খেলাধুলা',
    'প্রযুক্তি',
    'আন্তর্জাতিক',
    'বিনোদন',
    'স্বাস্থ্য',
    'শিক্ষা',
  ];

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(categoryNewsProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'এক্সপ্লোর',
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selector (Sticky-ish)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.black87,
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      showCheckmark: false, // Cleaner look
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 8),

          // News List
          Expanded(
            child: newsAsync.when(
              data: (newsList) {
                if (newsList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'এই বিভাগে এখনো কোনো সংবাদ নেই',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        // Seed Button for Dev (Optional, can remove for prod)
                        TextButton(
                           onPressed: () => ref.read(newsRepositoryProvider).seedDummyData(),
                           child: const Text('রিফ্রেশ করুন'),
                        )
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final news = newsList[index];
                    return SmartNewsCard(
                      news: news,
                      onTap: () {
                         // Note: Passing index 0 avoids crash, but reader pagination won't match.
                         // For Explore/Saved, we treat it as single-read mostly.
                        context.push('${AppConstants.newsReaderRoute}?index=0', extra: news);
                      },
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: 5,
                itemBuilder: (_, index) => _buildSkeletonCard(),
              ),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 300, 
          decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(16)
          ),
        ),
      ),
    );
  }
}
