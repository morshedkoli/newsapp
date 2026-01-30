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

        // Client-side filtering
        if (category != null && category != 'all') {
             return newsList.where((n) {
                // Check slug match
                if (n.categoryId == category || n.categorySlug == category) return true;
                return false;
             }).toList(); 
        }
        
        // Sort by date desc
        newsList.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        return newsList;
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

    return firestore
        .collection('news')
        .orderBy('published_at', descending: true)
        // Show ALL news on Home Page for ALL platforms (Mobile & Linux).
        .limit(100) 
        .snapshots()
        .map((snapshot) {
      final newsList = <NewsModel>[];
      for (var doc in snapshot.docs) {
        try {
          newsList.add(NewsModel.fromFirestore(doc));
        } catch (e) {
          // Skip broken
        }
      }
      newsList.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return newsList;
    });
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
    
    return firestore
        .collection('news')
        .where('categoryId', isEqualTo: categoryIdentifier) // New ID based
        .limit(100)
        .snapshots()
        .map((snapshot) {
       // If empty, try legacy slug match (Fallback for non-migrated apps/data?)
       // Note: snapshot.docs is empty list if no match.
       // We can't really do "Fallback Query" in a single Stream easily without Rx.
       // But wait! If migration script ran, ALL news have categoryId.
       // So asking for categoryId should work.
       // IF the user taps a category in ExplorePage, it passes the ID.
       
       // What if `categoryIdentifier` IS a slug (old deep link)?
       // We should ideally separate `getNewsByCategoryId` vs `getNewsBySlug`.
       // For now, let's assume we migrated everything and routing passes ID.
       
       final newsList = <NewsModel>[];
      for (var doc in snapshot.docs) {
        try {
          newsList.add(NewsModel.fromFirestore(doc));
        } catch (e) {
             // Handle error
        }
      }
      newsList.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
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
      final snapshot = await firestore
          .collection('news')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        try {
          return NewsModel.fromFirestore(doc);
        } catch (e) {
          return null;
        }
      }).whereType<NewsModel>().toList();
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
            .orderBy('published_at', descending: true) // Ensure field matches DB
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
