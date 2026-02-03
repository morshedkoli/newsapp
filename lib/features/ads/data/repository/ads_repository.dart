import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/platform_utils.dart';
import '../models/ads_config_model.dart';

class AdsRepository {
  final FirebaseFirestore? _firestore;
  final SharedPreferences? _prefs;
  
  static const String _cacheKey = 'ads_config_cache';

  AdsRepository({
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _firestore = firestore ?? (PlatformUtils.supportsFirebase ? FirebaseFirestore.instance : null),
        _prefs = prefs;

  /// Listen to real-time updates of ads configuration with local caching
  Stream<AdsConfig> getAdsConfigStream() {
    final firestore = _firestore;
    if (firestore == null) {
      // Return cached config or default
      return Stream.value(_getCachedConfig());
    }

    return firestore
        .collection('system_ads')
        .doc('config')
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.exists && snapshot.data() != null) {
              final config = AdsConfig.fromMap(snapshot.data()!);
              // Cache successful config
              _cacheConfig(config);
              return config;
            }
          } catch (e) {
            debugPrint('Error parsing ads config: $e');
          }
          // Return cached config on error, or default
          return _getCachedConfig();
        })
        .handleError((error) {
          debugPrint('Error fetching ads config: $error');
          // Return cached config on stream error
          return _getCachedConfig();
        });
  }

  /// Cache config to local storage
  Future<void> _cacheConfig(AdsConfig config) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toMap());
      await prefs.setString(_cacheKey, jsonString);
      debugPrint('Ads config cached successfully');
    } catch (e) {
      debugPrint('Failed to cache ads config: $e');
    }
  }

  /// Get cached config or default
  AdsConfig _getCachedConfig() {
    try {
      final prefs = _prefs;
      if (prefs != null) {
        final jsonString = prefs.getString(_cacheKey);
        if (jsonString != null) {
          final map = jsonDecode(jsonString) as Map<String, dynamic>;
          debugPrint('Using cached ads config');
          return AdsConfig.fromMap(map);
        }
      }
    } catch (e) {
      debugPrint('Failed to load cached ads config: $e');
    }
    debugPrint('Using default ads config (disabled)');
    return AdsConfig.defaultConfig();
  }

  /// Clear cached config (for testing/debugging)
  Future<void> clearCache() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('Ads config cache cleared');
    } catch (e) {
      debugPrint('Failed to clear ads config cache: $e');
    }
  }
}
