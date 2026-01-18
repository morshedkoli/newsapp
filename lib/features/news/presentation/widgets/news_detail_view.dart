import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class NewsDetailView extends ConsumerWidget {
  final String newsId;
  final String title;
  final String imageUrl;
  final String summary;
  final VoidCallback onReadMore;
  final VoidCallback onShare;

  const NewsDetailView({
    super.key,
    required this.newsId,
    required this.title,
    required this.imageUrl,
    required this.summary,
    required this.onReadMore,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A2 LAYOUT STRUCTURE (CRITICAL)
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header (Fixed Height Image) - optional per design, but sticking to scrollable content helps UX
            // However, "A2" says: SizedBox(height: HEADER_HEIGHT) ... Expanded(...)
            // We will put the image/title in the scrollable part as usual for tiktok style, 
            // BUT ensure NO extra nested wrappers exist.
            
            // Actually, to strictly follow A2 "Column with children", we do this:
            
             Expanded(
               child: SingleChildScrollView(
                 physics: const ClampingScrollPhysics(), // Android-safe
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Feature Image
                     SizedBox(
                       height: 300,
                       width: double.infinity,
                       child: Stack(
                         fit: StackFit.expand,
                         children: [
                           CachedNetworkImage(
                             imageUrl: imageUrl,
                             fit: BoxFit.cover,
                             placeholder: (context, url) => Shimmer.fromColors(
                               baseColor: Colors.grey.shade200,
                               highlightColor: Colors.grey.shade100,
                               child: Container(color: Colors.white),
                             ),
                             errorWidget: (context, url, error) => Container(
                               color: Colors.grey.shade100,
                               child: const Center(child: Icon(Icons.broken_image, 
                                 color: Colors.grey, size: 50)),
                             ),
                           ),
                           // Gradient
                           Positioned(
                             bottom: 0,
                             left: 0,
                             right: 0,
                             height: 80,
                             child: Container(
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   begin: Alignment.topCenter,
                                   end: Alignment.bottomCenter,
                                   colors: [
                                     Colors.transparent,
                                     Colors.white.withAlpha(0),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                     
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           // Title
                           Text(
                             title,
                             style: GoogleFonts.hindSiliguri(
                               fontSize: 24,
                               fontWeight: FontWeight.bold,
                               height: 1.3,
                               color: Colors.black87,
                             ),
                           ),
                           const SizedBox(height: 20),
                           
                           // Divider
                           Container(
                             width: 60,
                             height: 4,
                             decoration: BoxDecoration(
                               color: Colors.deepPurple,
                               borderRadius: BorderRadius.circular(2),
                             ),
                           ),
                           const SizedBox(height: 24),

                           // Summary
                           Text(
                             summary,
                             style: GoogleFonts.hindSiliguri(
                               fontSize: 18,
                               height: 1.7,
                               color: Colors.grey.shade900,
                               letterSpacing: 0.2,
                             ),
                           ),
                           const SizedBox(height: 32),
                           
                           // Buttons
                           SizedBox(
                             width: double.infinity,
                             child: ElevatedButton.icon(
                               onPressed: onReadMore,
                               icon: const Icon(Icons.open_in_new, size: 18),
                               label: const Text('মূল সংবাদ পড়ুন'),
                               style: ElevatedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 backgroundColor: Colors.black,
                                 foregroundColor: Colors.white,
                                 elevation: 0,
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 textStyle: GoogleFonts.hindSiliguri(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w600,
                                 ),
                               ),
                             ),
                           ),
                           const SizedBox(height: 20),
                           
                           SizedBox(
                             width: double.infinity,
                             child: OutlinedButton.icon(
                               onPressed: onShare,
                               icon: const Icon(Icons.share_rounded, size: 18),
                               label: const Text('শেয়ার করুন'),
                               style: OutlinedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 foregroundColor: Colors.black87,
                                 side: BorderSide(color: Colors.grey.shade300),
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 textStyle: GoogleFonts.hindSiliguri(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w600,
                                 ),
                               ),
                             ),
                           ),
                           const SizedBox(height: 100), // Spacing for Bottom Nav
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
