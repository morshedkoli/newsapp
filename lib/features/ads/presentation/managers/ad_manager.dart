import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/ads_provider.dart';
import '../../data/models/ads_config_model.dart';
import '../../../../core/theme/app_theme.dart';

final adManagerProvider = Provider((ref) => AdManager(ref));

class AdManager {
  final Ref _ref;
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  AdManager(this._ref);

  /// Increment interstitial counter and check if ad should be shown
  bool shouldShowInterstitial(AdPositionConfig config) {
    if (!config.enabled) return false;
    
    final currentCount = _ref.read(interstitialCounterProvider);
    final newItemCount = currentCount + 1;
    
    _ref.read(interstitialCounterProvider.notifier).state = newItemCount;

    if (newItemCount >= config.frequency) {
      // Reset counter
      _ref.read(interstitialCounterProvider.notifier).state = 0;
      return true;
    }
    
    return false;
  }

  /// Handle click on custom ads
  Future<void> handleCustomAdClick(String url) async {
    if (url.isEmpty) return;
    
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('❌ Could not launch ad URL: $url');
      }
    } catch (e) {
      debugPrint('❌ Error launching ad URL: $e');
    }
  }

  /// Check and Show Interstitial Ad
  Future<void> showInterstitial(BuildContext context) async {
    try {
      final config = _ref.read(adsConfigProvider).valueOrNull;
      if (config == null || !config.globalEnabled || !config.interstitial.enabled) return;

      if (!shouldShowInterstitial(config.interstitial)) return;

      final interstitialConfig = config.interstitial;

      if (interstitialConfig.provider == 'custom') {
        _showCustomInterstitial(context, interstitialConfig);
      } else if (interstitialConfig.provider == 'admob') {
        // Use test ad in debug mode
        final adUnitId = interstitialConfig.getAdUnitId(kDebugMode, AdsConfig.testInterstitialAdUnitId);
        await _showAdMobInterstitial(context, adUnitId);
      }
    } catch (e) {
      debugPrint('❌ Error showing interstitial ad: $e');
    }
  }

  void _showCustomInterstitial(BuildContext context, AdPositionConfig config) {
    if (config.customImageUrl.isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  handleCustomAdClick(config.customTargetUrl);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: config.customImageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) {
                      debugPrint('❌ Failed to load custom interstitial image: $error');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
              if (kDebugMode)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.green,
                    child: const Text('TEST AD', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing custom interstitial: $e');
    }
  }

  Future<void> _showAdMobInterstitial(BuildContext context, String unitId) async {
    if (_isAdLoading || unitId.isEmpty) return;

    _isAdLoading = true;
    
    try {
      await InterstitialAd.load(
          adUnitId: unitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              debugPrint('✅ Interstitial ad loaded successfully');
              _interstitialAd = ad;
              _isAdLoading = false;
              _interstitialAd!.show();
              _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
                onAdDismissedFullScreenContent: (InterstitialAd ad) {
                  debugPrint('Interstitial ad dismissed');
                  ad.dispose();
                },
                onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                  debugPrint('❌ Interstitial ad failed to show: $error');
                  ad.dispose();
                },
              );
            },
            onAdFailedToLoad: (LoadAdError error) {
              debugPrint('❌ Interstitial ad failed to load: $error');
              _isAdLoading = false;
            },
          ));
    } catch (e) {
      debugPrint('❌ Exception loading interstitial ad: $e');
      _isAdLoading = false;
    }
  }
}
