import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/platform_utils.dart';
import '../domain/category_model.dart';
import '../domain/news_model.dart';

// Pass null if not supported
final newsRepositoryProvider = Provider((ref) => NewsRepository(
  PlatformUtils.supportsFirebase ? FirebaseFirestore.instance : null
));

final newsStreamProvider = StreamProvider<List<NewsModel>>((ref) {
  return ref.watch(newsRepositoryProvider).getNews();
});

// New Provider for Category News
final categoryNewsProvider = StreamProvider.family<List<NewsModel>, String>((ref, category) {
  // Category passed here is now the SLUG (e.g. 'politics') from the Route
  return ref.watch(newsRepositoryProvider).getNewsByCategory(category);
});

// Provider for Categories (DERIVED FROM NEWS)
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(newsRepositoryProvider).getCategoriesFromCollection();
});


class NewsRepository {
  final FirebaseFirestore? _firestore; // Make nullable
  static const String _projectId = 'ainews-f6d83';
  static const String _baseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/news';

  NewsRepository(this._firestore);

  // Mock Data
  static final List<NewsModel> _mockNews = [
    NewsModel(
      id: '1',
      title: 'Active News Data Loading...',
      imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995',
      source: 'System',
      summary: 'Please wait while we fetch the latest updates.',
      publishedAt: DateTime.now(),
      categoryId: 'general',
      categorySlug: 'general',
      category: 'general',
      categoryName: 'সাধারণ',
      url: ''
    ),
  ];

  Future<List<NewsModel>> _fetchNewsRest({String? category}) async {
    try {
      // Use 100 limit globally for REST fallback as well
      const pageSize = 100; 
      final response = await http.get(Uri.parse('$_baseUrl?pageSize=$pageSize'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>?;
        
        if (documents == null) return [];

        final newsList = documents.map((doc) {
          try {
            return NewsModel.fromRestJson(doc);
          } catch (e) {
            debugPrint('Error parsing REST doc: $e');
            return null;
          }
        }).whereType<NewsModel>().toList();

        // Apply same filtering logic as admin panel and Firestore queries
        var filtered = newsList.where((news) {
          // Check if published based on status field or legacy published_at
          final hasPublishedAt = news.publishedAt != null;
          final isPublished = news.status == 'published' || 
                             (hasPublishedAt && (news.status == null || news.status!.isEmpty));
          return isPublished;
        }).toList();

        // Client-side category filtering if needed
        if (category != null && category != 'all') {
             filtered = filtered.where((n) {
               // Check slug match
               if (n.categoryId == category || n.categorySlug == category) return true;
               return false;
             }).toList(); 
        }
        
        // Sort by date desc
        filtered.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        return filtered;
      }
    } catch (e) {
      debugPrint('Error fetching REST news: $e');
    }
    return _mockNews;
  }

  Stream<List<NewsModel>> getNews() {
    final firestore = _firestore;
    if (firestore == null) {
      if (!kIsWeb) {
        return Stream.fromFuture(_fetchNewsRest());
      }
      return Stream.value([]);
    }

    // Use a controller to handle errors gracefully
    return _fetchNewsWithFallback(firestore).asStream();
  }

  Future<List<NewsModel>> _fetchNewsWithFallback(FirebaseFirestore firestore) async {
    try {
      // Match admin panel approach: fetch all news ordered by created_at
      // Then filter client-side to handle both new status field and legacy data
      final snapshot = await firestore
          .collection('news')
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      final newsList = <NewsModel>[];
      for (var doc in snapshot.docs) {
        try {
          final news = NewsModel.fromFirestore(doc);
          final data = doc.data();
          final hasPublishedAt = data['published_at'] != null;
          final hasStatus = data['status'] != null && (data['status'] as String).isNotEmpty;
          
          // Match admin panel logic exactly:
          // Show if status == 'published' OR (has published_at but no status - legacy data)
          final isPublished = news.status == 'published' || 
                              (hasPublishedAt && !hasStatus);
          
          if (isPublished) {
            newsList.add(news);
          }
        } catch (e) {
          debugPrint('Error parsing news doc: $e');
        }
      }
      
      // Already ordered by created_at from Firestore, no need to sort
      return newsList;
    } catch (e) {
      debugPrint('News query failed: $e');
      
      // Fallback: try REST API for non-web platforms
      if (!kIsWeb) {
        return _fetchNewsRest();
      }
      return [];
    }
  }

  // Get News by Category ID (Primary) or Slug (Legacy Fallback)
  Stream<List<NewsModel>> getNewsByCategory(String categoryIdentifier) {
    if (categoryIdentifier.isEmpty) return Stream.value([]);

    final firestore = _firestore;
    if (firestore == null) {
       // REST fallback (still uses slug likely, unless REST API updated)
       if (!kIsWeb) {
         return Stream.fromFuture(_fetchNewsRest(category: categoryIdentifier));
       }
      return Stream.value([]);
    }

    // Attempt to query by categoryId first (Assuming identifier is ID)
    // But since we just pushed IDs, we can trust it's an ID if it doesn't look like a slug?
    // Actually, simple approach: Query 'categoryId' == id.
    // If empty (or for legacy support), we might need to handle slug.
    // However, migration is done. We should use `categoryId`.
    
    // Fetch by categoryId, then filter for published items client-side
    return firestore
        .collection('news')
        .where('categoryId', isEqualTo: categoryIdentifier)
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
       final newsList = <NewsModel>[];
      for (var doc in snapshot.docs) {
        try {
          final news = NewsModel.fromFirestore(doc);
          final data = doc.data();
          final hasPublishedAt = data['published_at'] != null;
          final hasStatus = data['status'] != null && (data['status'] as String).isNotEmpty;
          
          // Match admin panel logic: published or legacy data
          final isPublished = news.status == 'published' || (hasPublishedAt && !hasStatus);
          
          if (isPublished) {
            newsList.add(news);
          }
        } catch (e) {
             // Skip invalid docs
        }
      }
      // Already sorted by created_at from Firestore
      return newsList;
    });
  }
  
  // NEW: Fetch Valid Categories from 'categories' collection
  Future<List<CategoryModel>> getCategoriesFromCollection() async {
    final firestore = _firestore;
    if (firestore == null) return getDerivedCategories(); // Fallback

    try {
      final snapshot = await firestore
          .collection('categories')
          .where('enabled', isEqualTo: true)
          .where('postCount', isGreaterThan: 0)
          .orderBy('postCount', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CategoryModel(
          id: doc.id,
          name: data['name'] ?? '',
          slug: data['slug'] ?? '',
          postCount: data['postCount'] ?? 0,
          enabled: data['enabled'] ?? true,
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching categories collection: $e");
      return getDerivedCategories(); // Fallback to scanning if collection fails
    }
  }

  Future<List<NewsModel>> searchNews(String query) async {
    final firestore = _firestore;
    if (firestore == null) {
       if (!kIsWeb && query.isNotEmpty) {
          final allNews = await _fetchNewsRest();
          return allNews.where((n) => n.title.contains(query)).toList();
       }
       return [];
    }
    if (query.isEmpty) return [];

    try {
      // Fetch matching titles, then filter for published items client-side
      final snapshot = await firestore
          .collection('news')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      final results = <NewsModel>[];
      for (var doc in snapshot.docs) {
        try {
          final news = NewsModel.fromFirestore(doc);
          final data = doc.data();
          final hasPublishedAt = data['published_at'] != null;
          final hasStatus = data['status'] != null && (data['status'] as String).isNotEmpty;
          
          // Match admin panel logic: published or legacy data
          final isPublished = news.status == 'published' || (hasPublishedAt && !hasStatus);
          
          if (isPublished) {
            results.add(news);
          }
        } catch (e) {
          // Skip invalid docs
        }
      }
      return results.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<NewsModel?> getNewsById(String newsId) async {
    final firestore = _firestore;
    if (firestore == null) {
       if (!kIsWeb) {
         try {
           final news = await _fetchNewsRest();
           return news.firstWhere((n) => n.id == newsId);
         } catch (_) {
           return null;
         }
       }
       return null;
    }

    try {
      final doc = await firestore.collection('news').doc(newsId).get();
      if (doc.exists) {
        return NewsModel.fromFirestore(doc);
      }
    } catch (e) {
      // Error
    }
    return null;
  }

  // ==========================================
  // DYNAMIC CATEGORY FETCHING (FROM NEWS DATA)
  // ==========================================
  Future<List<CategoryModel>> getDerivedCategories() async {
    debugPrint('Fetching dynamic categories from news...');
    
    List<NewsModel> recentNews = [];
    final firestore = _firestore;

    // 1. Fetch News (Firestore or REST)
    if (firestore == null) {
      if (!kIsWeb) {
        recentNews = await _fetchNewsRest();
      }
    } else {
      try {
        final snapshot = await firestore
            .collection('news')
            .where('status', isEqualTo: 'published')
            .orderBy('created_at', descending: true) // Match admin panel ordering
            .limit(100) 
            .get();
        
        recentNews = snapshot.docs.map((doc) {
           try {
             return NewsModel.fromFirestore(doc);
           } catch (_) { return null; }
        }).whereType<NewsModel>().toList();
      } catch (e) {
         // Fallback if 'published_at' index missing or field wrong
         debugPrint('Error fetching news for categories: $e');
         // Try fetching without sort if index fails
         try {
            final snapshot = await firestore.collection('news').limit(50).get();
            recentNews = snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList();
         } catch (_) {}
      }
    }

    // 2. Extract & Deduplicate
    final categoryMap = <String, CategoryModel>{};

    for (var news in recentNews) {
       if (news.categorySlug.isEmpty) continue;
       
       final slug = news.categorySlug;
       final name = news.categoryName.isNotEmpty ? news.categoryName : slug;

       // Count posts
       if (categoryMap.containsKey(slug)) {
          final existing = categoryMap[slug]!;
          categoryMap[slug] = CategoryModel(
            id: existing.id.isNotEmpty ? existing.id : news.categoryId, // Try to capture ID if widely available
            name: existing.name,
            slug: existing.slug,
            postCount: existing.postCount + 1,
            enabled: true,
          );
       } else {
          categoryMap[slug] = CategoryModel(
            id: news.categoryId.isNotEmpty ? news.categoryId : slug, // Prefer ID if available
            slug: slug,
            name: name,
            postCount: 1,
            enabled: true,
          );
       }
    }

    final categories = categoryMap.values.toList();
    
    // 3. Sort (Most popular first)
    categories.sort((a, b) => b.postCount.compareTo(a.postCount));
    
    return categories;
  }

  // Deprecated: getCategories (Renamed to prevent usage of old logic)
  Future<List<CategoryModel>> getCategories() => getDerivedCategories();

  Future<void> seedDummyData() async {
    // No-op for now
  }
}
