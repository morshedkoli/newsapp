import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_utils.dart'; // Import
import '../../../../core/widgets/safe_network_image.dart'; // Import

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
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
             Expanded(
               child: SingleChildScrollView(
                 physics: const ClampingScrollPhysics(),
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
                           SafeNetworkImage(
                             url: imageUrl,
                             fit: BoxFit.cover,
                             placeholder: (context, url) => Shimmer.fromColors(
                               baseColor: AppTheme.primaryLight,
                               highlightColor: Colors.white,
                               child: Container(color: Colors.white),
                             ),
                             errorWidget: (context, url, error) => Container(
                               color: AppTheme.primaryLight,
                               child: Center(child: Icon(Icons.broken_image, 
                                 color: AppTheme.primaryColor.withAlpha((0.5 * 255).round()), size: 50)),
                             ),
                           ),
                           // Gradient overlay for text readability
                           Positioned(
                             bottom: 0,
                             left: 0,
                             right: 0,
                             height: 100,
                             child: Container(
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   begin: Alignment.topCenter,
                                   end: Alignment.bottomCenter,
                                   colors: [
                                     Colors.transparent,
                                     Colors.white.withAlpha((0.8 * 255).round()),
                                     Colors.white,
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
                             style: GoogleFonts.tiroBangla(
                               fontSize: 24,
                               fontWeight: FontWeight.bold,
                               height: 1.3,
                               color: Colors.black87,
                             ),
                           ),
                           const SizedBox(height: 20),
                           
                           // Gradient Divider
                           Container(
                             width: 80,
                             height: 4,
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 colors: [AppTheme.primaryColor, AppTheme.accentColor],
                               ),
                               borderRadius: BorderRadius.circular(2),
                             ),
                           ),
                           const SizedBox(height: 24),

                           // Summary
                           Text(
                             summary,
                             style: GoogleFonts.tiroBangla(
                               fontSize: 18,
                               height: 1.7,
                               color: Colors.grey.shade900,
                               letterSpacing: 0.2,
                             ),
                           ),
                           const SizedBox(height: 32),
                           
                           // Read More Button with Gradient
                           SizedBox(
                             width: double.infinity,
                             child: Container(
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                                 ),
                                 borderRadius: BorderRadius.circular(14),
                                 boxShadow: [
                                   BoxShadow(
                                     color: AppTheme.primaryColor.withAlpha((0.3 * 255).round()),
                                     blurRadius: 12,
                                     offset: const Offset(0, 4),
                                   ),
                                 ],
                               ),
                               child: ElevatedButton.icon(
                                 onPressed: onReadMore,
                                 icon: const Icon(Icons.open_in_new, size: 18),
                                 label: const Text('মূল সংবাদ পড়ুন'),
                                 style: ElevatedButton.styleFrom(
                                   padding: const EdgeInsets.symmetric(vertical: 16),
                                   backgroundColor: Colors.transparent,
                                   shadowColor: Colors.transparent,
                                   foregroundColor: Colors.white,
                                   elevation: 0,
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(14),
                                   ),
                                   textStyle: GoogleFonts.tiroBangla(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                               ),
                             ),
                           ),
                           const SizedBox(height: 16),
                           
                           // Share Button
                           SizedBox(
                             width: double.infinity,
                             child: OutlinedButton.icon(
                               onPressed: onShare,
                               icon: Icon(Icons.share_rounded, size: 18, color: AppTheme.primaryColor),
                               label: Text('শেয়ার করুন', style: TextStyle(color: AppTheme.primaryDark)),
                               style: OutlinedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 foregroundColor: AppTheme.primaryColor,
                                 side: BorderSide(color: AppTheme.primaryColor.withAlpha((0.5 * 255).round()), width: 1.5),
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(14),
                                 ),
                                 textStyle: GoogleFonts.tiroBangla(
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
