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
  
  // New Fields
  final String categoryId;
  final String categorySlug;

  // Legacy Fields (Deprecated)
  @Deprecated('Use categorySlug instead')
  final String category; // Slug
  @Deprecated('Use categoryName from CategoryModel instead')
  final String categoryName; // Display Name
  
  final String url;
  final String status;

  NewsModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.source,
    required this.summary,
    required this.publishedAt,
    this.categoryId = '',
    this.categorySlug = '',
    @Deprecated('Use categorySlug') this.category = 'general',
    @Deprecated('Use categoryName') this.categoryName = 'সাধারণ',
    this.url = '',
    this.status = 'published',
  });

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Logic for Image: Check 'image' then 'imageUrl', then 'feature_image'
    String? img = data['image'] as String?;
    if (img == null || img.isEmpty) {
      img = data['imageUrl'] as String?;
    }
    if (img == null || img.isEmpty) {
      img = data['feature_image'] as String?;
    }
    if (img == null || img.isEmpty) {
      img = data['thumbnail'] as String?;
    }
    
    final String finalImageUrl;
    if (img != null && img.isNotEmpty && img.startsWith('http')) {
      finalImageUrl = AppConstants.getImageUrl(img);
    } else {
      finalImageUrl = AppConstants.defaultNewsImageUrl;
    }
    
    // Logic for Source: Check 'source_name' then 'source'
    String? src = data['source_name'] as String?;
    if (src == null || src.isEmpty) {
      src = data['source'] as String?;
    }

    // Logic for URL
    String? link = data['source_url'] as String?;
    if (link == null || link.isEmpty) {
      link = data['link'] as String?;
    }
    if (link == null || link.isEmpty) {
      link = data['url'] as String?;
    }
    if (link == null || link.isEmpty) {
      link = data['article_url'] as String?;
    }

    // Category Logic (New Scheme)
    // 1. Try reading strict fields
    String catId = data['categoryId'] as String? ?? '';
    String catSlug = data['categorySlug'] as String? ?? '';

    // 2. Fallback to legacy if missing
    if (catSlug.isEmpty) {
       catSlug = data['category'] as String? ?? 'general';
    }
    // Note: We can't easily fallback ID from slug without a map, so empty ID is possible if not backfilled.

    return NewsModel(
      id: doc.id,
      title: data['title'] as String? ?? 'No Title',
      imageUrl: finalImageUrl,
      source: (src != null && src.isNotEmpty) ? src : 'Unknown Source',
      summary: data['summary'] as String? ?? 'সংক্ষেপ নেই',
      publishedAt: _parseDateTime(data),
      categoryId: catId,
      categorySlug: catSlug,
      // Legacy mapping for backward compat
      category: catSlug,
      categoryName: data['category_name'] as String? ?? (catSlug == 'general' ? 'সাধারণ' : catSlug),
      url: (link != null && link.isNotEmpty) ? link : '',
      status: data['status'] as String? ?? 'published',
    );
  }

  factory NewsModel.fromRestJson(Map<String, dynamic> json) {
    final fields = json['fields'] as Map<String, dynamic>? ?? {};
    
    String getString(String key) {
      if (!fields.containsKey(key)) return '';
      final field = fields[key] as Map<String, dynamic>;
      return field['stringValue'] as String? ?? '';
    }

    // Image Logic
    String img = getString('image');
    if (img.isEmpty) img = getString('imageUrl');
    if (img.isEmpty) img = getString('feature_image');
    if (img.isEmpty) img = getString('thumbnail');
    
    final String finalImageUrl;
    if (img.isNotEmpty && img.startsWith('http')) {
      finalImageUrl = AppConstants.getImageUrl(img);
    } else {
      finalImageUrl = AppConstants.defaultNewsImageUrl;
    }

    // Source Logic
    String src = getString('source_name');
    if (src.isEmpty) src = getString('source');

    // URL Logic
    String link = getString('source_url');
    if (link.isEmpty) link = getString('link');
    if (link.isEmpty) link = getString('url');
    if (link.isEmpty) link = getString('article_url');

    // Date Logic
    DateTime publishedDate = DateTime.now();
    
    DateTime? parseRestDate(String key) {
      if (!fields.containsKey(key)) return null;
      final field = fields[key] as Map<String, dynamic>;
      
      if (field.containsKey('timestampValue')) {
        return DateTime.tryParse(field['timestampValue']);
      }
      if (field.containsKey('stringValue')) {
        return DateTime.tryParse(field['stringValue']);
      }
      return null;
    }

    publishedDate = parseRestDate('publishedAt') ?? 
                    parseRestDate('published_at') ?? 
                    DateTime.now();

    // Extract ID
    String docId = '';
    if (json.containsKey('name')) {
      final nameParts = (json['name'] as String).split('/');
      if (nameParts.isNotEmpty) docId = nameParts.last;
    }

    String catId = getString('categoryId');
    String catSlug = getString('categorySlug');
    if (catSlug.isEmpty) catSlug = getString('category').isNotEmpty ? getString('category') : 'general';

    return NewsModel(
      id: docId,
      title: getString('title').isNotEmpty ? getString('title') : 'No Title',
      imageUrl: finalImageUrl,
      source: src.isNotEmpty ? src : 'Unknown Source',
      summary: getString('summary').isNotEmpty ? getString('summary') : 'সংক্ষেপ নেই',
      publishedAt: publishedDate,
      categoryId: catId,
      categorySlug: catSlug,
      category: catSlug,
      categoryName: getString('category_name').isNotEmpty ? getString('category_name') : (catSlug == 'general' ? 'সাধারণ' : catSlug),
      url: link,
      status: getString('status').isNotEmpty ? getString('status') : 'published',
    );
  }

  static DateTime _parseDateTime(Map<String, dynamic> data) {
    // Try created_at first (matches admin panel ordering)
    if (data.containsKey("created_at")) {
      final val = data["created_at"];
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    }
    
    // Fallback to publishedAt for legacy compatibility
    if (data.containsKey("publishedAt")) {
      final val = data["publishedAt"];
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    }
    
    // Fallback to published_at
    if (data.containsKey("published_at")) {
      final val = data["published_at"];
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    }

    return DateTime.now();
  }

  String get timeAgo => timeago.format(publishedAt);
}
