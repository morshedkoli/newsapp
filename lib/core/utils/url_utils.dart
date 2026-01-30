import 'package:flutter/foundation.dart';

class UrlUtils {
  /// Safely sanitizes a URL string to prevent "Illegal percent encoding" errors.
  /// 
  /// 1. Trims whitespace.
  /// 2. Returns empty string if null or empty.
  /// 3. Returns null if invalid or cannot be parsed.
  /// 4. Encodes full URL if parsing fails initially.
  static String sanitizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return '';
    }
    
    final trimmed = rawUrl.trim();
    
    try {
      // Test parse
      Uri.parse(trimmed);
      return trimmed;
    } catch (e) {
      // If failed, try encoding
      try {
        final encoded = Uri.encodeFull(trimmed);
        Uri.parse(encoded); // Validate again
        return encoded;
      } catch (_) {
        debugPrint('❌ Critical: Failed to sanitize URL: $rawUrl');
        return '';
      }
    }
  }

  /// Returns a safe Uri object or null if completely invalid
  static Uri? getSafeUri(String? rawUrl) {
    final sanitized = sanitizeUrl(rawUrl);
    if (sanitized.isEmpty) return null;
    try {
      return Uri.parse(sanitized);
    } catch (_) {
      return null;
    }
  }
}
