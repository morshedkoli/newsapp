import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:newsbyte_bd/core/constants/app_constants.dart';
import 'package:newsbyte_bd/core/theme/app_theme.dart';

import '../../home/presentation/widgets/smart_news_card.dart';
import '../../news/data/news_repository.dart';
import '../../news/presentation/news_search_delegate.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    // Watch the new provider which returns List<CategoryModel>
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
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
                  colors: [Color(0xFF00BFA5), Color(0xFF00897B)], // Hardcoded AppTheme colors
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
        centerTitle: false,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Active Categories Label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'জনপ্রিয় বিভাগসমূহ', // "Popular Categories"
                style: GoogleFonts.tiroBangla(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categories Grid
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                           SizedBox(height: 16),
                           Text('কোনো বিভাগ পাওয়া যায়নি', style: GoogleFonts.tiroBangla(color: Colors.grey)),
                         ],
                       ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3, // Slightly taller for badge
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      // Use name for styling mapping as it's consistent with existing map
                      final style = _getDynamicStyle(category.name);
                      
                      return GestureDetector(
                        onTap: () {
                           // ✅ Safe Navigation using ID
                           // Title is still passed for UI immediate feedback
                           final safeTitle = Uri.encodeComponent(category.name);
                           
                           final route = '/category/${category.id}?title=$safeTitle';
                           context.push(route);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: style.color.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        style.icon,
                                        color: style.color,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      category.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.tiroBangla(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Post Count Badge (Optional)
                              if (category.postCount > 0)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${category.postCount}',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => _buildShimmerGrid(),
                error: (e, st) => Center(
                   child: Text(
                     'Failed to load categories',
                     style: TextStyle(color: Colors.red),
                   )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Loading Skeleton
  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Dynamic Style Generator
  _CategoryStyle _getDynamicStyle(String category) {
    // Curated list for common ones (Best UX)
    switch (category) {
      case 'জাতীয়': return _CategoryStyle(Icons.flag, Colors.green);
      case 'আন্তর্জাতিক': return _CategoryStyle(Icons.public, Colors.blue);
      case 'রাজনীতি': return _CategoryStyle(Icons.gavel, Colors.deepOrange);
      case 'খেলা': return _CategoryStyle(Icons.sports_soccer, Colors.indigo);
      case 'খেলাধুলা': return _CategoryStyle(Icons.sports_soccer, Colors.indigo); // Variant
      case 'প্রযুক্তি': return _CategoryStyle(Icons.memory, Colors.purple);
      case 'অর্থনীতি': return _CategoryStyle(Icons.attach_money, Colors.teal);
      case 'বিনোদন': return _CategoryStyle(Icons.movie, Colors.pink);
      case 'স্বাস্থ্য': return _CategoryStyle(Icons.health_and_safety, Colors.redAccent);
      case 'শিক্ষা': return _CategoryStyle(Icons.school, Colors.amber.shade700);
      case 'লাইফস্টাইল': return _CategoryStyle(Icons.style, Colors.cyan);
      case 'মতামত': return _CategoryStyle(Icons.forum, Colors.brown);
      case 'ধর্ম': return _CategoryStyle(Icons.mosque, Colors.green.shade800);
    }
    
    // Fallback: Generate generic icon/color based on string hash to be consistent
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo
    ];
    final color = colors[category.hashCode.abs() % colors.length];
    
    return _CategoryStyle(Icons.article, color);
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color color;
  _CategoryStyle(this.icon, this.color);
}
