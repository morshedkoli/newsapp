import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:newsbyte_bd/core/constants/app_constants.dart';

class NewsModel {
  final String id;
  final String title;
  final String imageUrl;
  final String source;
  final String summary;
  final DateTime publishedAt;
  final String category;

  NewsModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.source,
    required this.summary,
    required this.publishedAt,
    this.category = 'সাধারণ',
  });

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Logic for Image: Check 'image' then 'imageUrl'
    String? img = data['image'] as String?;
    if (img == null || img.isEmpty) {
      img = data['imageUrl'] as String?;
    }
    
    // Logic for Source: Check 'source_name' then 'source'
    String? src = data['source_name'] as String?;
    if (src == null || src.isEmpty) {
      src = data['source'] as String?;
    }

    return NewsModel(
      id: doc.id,
      title: data['title'] as String? ?? 'No Title',
      imageUrl: (img != null && img.isNotEmpty) ? img : AppConstants.defaultNewsImageUrl,
      source: (src != null && src.isNotEmpty) ? src : 'Unknown Source',
      summary: data['summary'] as String? ?? 'সংক্ষেপ নেই',
      publishedAt: _parseDateTime(data),
      category: data['category'] as String? ?? 'সাধারণ',
    );
  }

  // Unified parser for mixed-type date fields (Timestamp vs String)
  static DateTime _parseDateTime(Map<String, dynamic> data) {
    // Try 'publishedAt' (camelCase)
    if (data.containsKey('publishedAt')) {
      final val = data['publishedAt'];
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    }
    
    // Try 'published_at' (snake_case)
    if (data.containsKey('published_at')) {
      final val = data['published_at'];
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    }

    // Fallback
    return DateTime.now();
  }

  String get timeAgo => timeago.format(publishedAt);
}
