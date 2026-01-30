import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return _buildPlaceholder(context);
    }

    try {
      final trimmed = url!.trim();
      // Ensure it's encoded
      String safeUrl = trimmed;
      try {
         Uri.parse(trimmed); // check if valid already
      } catch(_) {
         safeUrl = Uri.encodeFull(trimmed);
      }

      return CachedNetworkImage(
        imageUrl: safeUrl,
        fit: fit,
        placeholder: placeholder ?? (context, url) => _buildPlaceholder(context),
        errorWidget: errorWidget ?? (context, url, error) {
           debugPrint('❌ IMAGE LOAD ERROR: $error for URL: $url');
           return _buildErrorPlaceholder(context);
        },
      );
    } catch (e) {
      debugPrint('❌ IMAGE URI ERROR: $url - $e');
      return _buildErrorPlaceholder(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
