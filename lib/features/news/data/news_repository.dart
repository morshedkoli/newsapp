import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/news_model.dart';

final newsRepositoryProvider = Provider((ref) => NewsRepository(FirebaseFirestore.instance));

final newsStreamProvider = StreamProvider<List<NewsModel>>((ref) {
  return ref.watch(newsRepositoryProvider).getNews();
});

// New Provider for Category News
final categoryNewsProvider = StreamProvider.family<List<NewsModel>, String>((ref, category) {
  return ref.watch(newsRepositoryProvider).getNewsByCategory(category);
});

class NewsRepository {
  final FirebaseFirestore _firestore;

  NewsRepository(this._firestore);

  Stream<List<NewsModel>> getNews() {
    return _firestore
        .collection('news')
        .limit(20) 
        .snapshots()
        .map((snapshot) {
      final newsList = <NewsModel>[];
      for (var doc in snapshot.docs) {
        try {
          newsList.add(NewsModel.fromFirestore(doc));
        } catch (e) {
          // Skip broken doc
        }
      }
      newsList.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return newsList;
    });
  }

  // Get News by Category
  Stream<List<NewsModel>> getNewsByCategory(String category) {
    Query query = _firestore.collection('news');
    
    if (category != 'সব') { // 'All' check
       query = query.where('category', isEqualTo: category);
    }

    return query.limit(20).snapshots().map((snapshot) {
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

  // Get Single News by ID (Deep Link Support)
  Future<NewsModel?> getNewsById(String newsId) async {
    try {
      final doc = await _firestore.collection('news').doc(newsId).get();
      if (doc.exists) {
        return NewsModel.fromFirestore(doc);
      }
    } catch (e) {
      // Error fetching news
    }
    return null;
  }

  Future<void> seedDummyData() async {
     final newsCollection = _firestore.collection('news');
    // Basic check to see if we have categorised data
    // For manual seeding only
    
    final List<Map<String, dynamic>> dummyNews = [
      {
        'title': 'বাংলাদেশে এআই প্রযুক্তির নতুন দিগন্ত',
        'imageUrl': 'https://images.unsplash.com/photo-1677442136019-21780ecad995',
        'source': 'টেক নিউজ বিডি',
        'summary': 'নতুন এআই মডেল যা বাংলা ভাষা বুঝতে পারে।',
        'publishedAt': DateTime.now().toIso8601String(),
        'category': 'প্রযুক্তি'
      },
      {
        'title': 'ক্রিকেট ও ফুটবল দলের নতুন সময়সূচি',
        'imageUrl': 'https://images.unsplash.com/photo-1531415074984-dfa4f91041c0',
        'source': 'খেলার খবর',
        'summary': 'আগামী মাসের টুর্নামেন্ট নিয়ে উত্তেজনা তুঙ্গে।',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'category': 'খেলাধুলা'
      },
       {
        'title': 'বিশ্ব অর্থনীতিতে মন্দার প্রভাব',
        'imageUrl': 'https://images.unsplash.com/photo-1611974765270-ca6e1128adeb',
        'source': 'আন্তর্জাতিক',
        'summary': 'বিশ্ব বাজারে তেলের দাম বৃদ্ধি।',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String(),
        'category': 'অর্থনীতি'
      },
       {
        'title': 'নতুন শিক্ষানীতি ঘোষণা',
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b',
        'source': 'শিক্ষা সংবাদ',
        'summary': 'প্রাথমিক শিক্ষায় বড় পরিবর্তন আসছে।',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'category': 'শিক্ষা'
      },
      {
        'title': 'শীতকালীন পিঠা উৎসব',
        'imageUrl': 'https://images.unsplash.com/photo-1543158098-e679b38ed616',
        'source': 'লাইফস্টাইল',
        'summary': 'গ্রাম বাংলার ঐতিহ্যবাহী উৎসব।',
        'publishedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'category': 'বিনোদন'
      },
    ];

    for (var news in dummyNews) {
      await newsCollection.add(news);
    }
  }
}
