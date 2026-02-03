import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../core/utils/platform_utils.dart';

import '../providers/ads_provider.dart';

final adsInitializationServiceProvider = Provider((ref) => AdsInitializationService(ref));

/// Service to handle conditional AdMob SDK initialization
class AdsInitializationService {
  final Ref _ref;
  bool _isInitialized = false;

  AdsInitializationService(this._ref);

  /// Initialize AdMob SDK only if ads are enabled and platform supports it
  Future<void> initialize() async {
    // Platform check
    if (!PlatformUtils.supportsAds) {
      debugPrint('📱 Platform does not support ads, skipping initialization');
      return;
    }

    // Already initialized
    if (_isInitialized) {
      debugPrint('✅ AdMob SDK already initialized');
      return;
    }

    try {
      // Wait for ads config
      final config = _ref.read(adsConfigProvider).valueOrNull;
      
      if (config == null) {
        debugPrint('⚠️ Ads config not available, deferring initialization');
        // Will be initialized later when config loads
        return;
      }

      // Check if ads are globally enabled
      if (!config.globalEnabled) {
        debugPrint('🚫 Ads globally disabled, skipping SDK initialization');
        return;
      }

      // Initialize SDK
      debugPrint('🚀 Initializing AdMob SDK...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdMob SDK initialized successfully');
      
      if (kDebugMode) {
        debugPrint('🧪 Debug mode: Test ads will be used');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize AdMob SDK: $e');
      // Don't throw - app should continue without ads
    }
  }

  /// Check if SDK is initialized
  bool get isInitialized => _isInitialized;
}
