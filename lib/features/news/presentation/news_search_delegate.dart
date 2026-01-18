import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/news_repository.dart';
import '../domain/news_model.dart';
import '../../home/presentation/widgets/smart_news_card.dart';

class NewsSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  NewsSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('অনুসন্ধান করতে লিখুন...'));
    }

    // Since our repo uses Future for search, currently we use FutureBuilder
    // A better approach would be to use a separate FutureProvider with family, 
    // but for simplicity calling repo directly here is okay for MVP
    return FutureBuilder<List<NewsModel>>(
      future: ref.read(newsRepositoryProvider).searchNews(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
           return const Center(child: Text('কিছু ভুল হয়েছে'));
        }

        final newsList = snapshot.data ?? [];

        if (newsList.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'কোনো ফলাফল পাওয়া যায়নি',
                   style: GoogleFonts.hindSiliguri(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
             final news = newsList[index];
              return SmartNewsCard(
                news: news,
                onTap: () {
                  // Navigate using news ID (Firestore docs always have IDs)
                  context.push('/news/${news.id}');
                },
              );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
     return Center(
       child: Text(
         'খবর খুঁজুন',
         style: GoogleFonts.hindSiliguri(fontSize: 16, color: Colors.grey),
       ),
     );
  }

  @override
  String get searchFieldLabel => 'অনুসন্ধান করুন...';
  
  @override
  TextStyle get searchFieldStyle => GoogleFonts.hindSiliguri(fontSize: 18);
}
