import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'NewsByte';
  static const String tagline = 'মূল খবর, বাড়তি কথা নয়।';
  
  // Routes
  static const String splashRoute = '/splash';
  static const String welcomeRoute = '/welcome';
  static const String homeRoute = '/';
  static const String newsReaderRoute = '/reader';
  static const String ollamaApiUrl = 'http://localhost:11434';
  
  // Assets - Using a reliable placeholder image
  static const String defaultNewsImageUrl = 'https://placehold.co/800x450/00BFA5/white?text=NewsByte';
  
  // API
  static const String apiBaseUrl = 'https://news-9v14.vercel.app';
  
  /// Returns image URL - routes through proxy on web for CORS
  static String getImageUrl(String originalUrl) {
    // Skip if empty or already a placeholder
    if (originalUrl.isEmpty) {
      return defaultNewsImageUrl;
    }
    
    // On web, use the proxy to bypass CORS
    if (kIsWeb) {
      // Skip proxy for placehold.co (already CORS-friendly)
      if (originalUrl.contains('placehold.co')) {
        return originalUrl;
      }
      return '$apiBaseUrl/api/image-proxy?url=${Uri.encodeComponent(originalUrl)}';
    }
    
    // On mobile, use original URL directly
    return originalUrl;
  }
}
