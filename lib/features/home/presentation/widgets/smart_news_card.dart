import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../news/domain/news_model.dart';
import 'news_card.dart';

class SmartNewsCard extends ConsumerWidget {
  final NewsModel news;
  final VoidCallback onTap;
  
  const SmartNewsCard({
    super.key, 
    required this.news,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NewsCard(
      title: news.title,
      imageUrl: news.imageUrl,
      source: news.source,
      timeAgo: news.timeAgo,
      onTap: onTap,
    );
  }
}
