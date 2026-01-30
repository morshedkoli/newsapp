import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../home/presentation/widgets/smart_news_card.dart';
import '../data/news_repository.dart';

class CategoryNewsPage extends ConsumerWidget {
  final String categoryId; 
  final String? categoryTitle; 

  const CategoryNewsPage({
    super.key,
    required this.categoryId,
    this.categoryTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pass the ID to the provider/repo
    final newsAsync = ref.watch(categoryNewsProvider(categoryId));

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          // Use Bangla Title if provided
          categoryTitle ?? 'News',
          style: GoogleFonts.tiroBangla(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: newsAsync.when(
        data: (newsList) {
          if (newsList.isEmpty) {
            return Center(
              child: Text(
                'এই ক্যাটাগরিতে কোনো সংবাদ নেই',
                style: GoogleFonts.tiroBangla(fontSize: 18),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final news = newsList[index];
              return SmartNewsCard(
                news: news,
                onTap: () {
                  context.push('/news/${news.id}');
                },
              );
            },
          );
        },
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
