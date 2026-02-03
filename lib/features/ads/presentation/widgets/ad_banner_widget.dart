import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/platform_utils.dart';
import '../providers/ads_provider.dart';
import '../managers/ad_manager.dart';
import '../../data/models/ads_config_model.dart';

class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _hasError = false;

  void _loadAd(String unitId) {
    if (_bannerAd != null || _hasError) return; // Already loaded or failed

    try {
      BannerAd(
        adUnitId: unitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _bannerAd = ad as BannerAd;
                _isAdLoaded = true;
                _hasError = false;
              });
              debugPrint('✅ Banner ad loaded successfully');
            }
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('❌ Failed to load banner ad: ${err.message}');
            ad.dispose();
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          },
        ),
      ).load();
    } catch (e) {
      debugPrint('❌ Exception loading banner ad: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsConfigAsync = ref.watch(adsConfigProvider);

    return adsConfigAsync.when(
      data: (config) {
        // Global switch check
        if (!config.globalEnabled || !config.banner.enabled) {
          return const SizedBox.shrink();
        }

        final bannerConfig = config.banner;

        // Platform Check: Don't show AdMob if not supported, unless it's a Custom Ad which works everywhere
        if (!PlatformUtils.supportsAds && bannerConfig.provider != 'custom') {
           if (kDebugMode) {
             return Container(
               height: 50,
               color: Colors.orange.withOpacity(0.2),
               alignment: Alignment.center,
               child: Text("Ads Not Supported on ${Platform.operatingSystem} (Provider: ${bannerConfig.provider})", style: const TextStyle(fontSize: 10)),
             );
           }
           return const SizedBox.shrink();
        }

        // Custom Ad
        if (bannerConfig.provider == 'custom') {
           if (bannerConfig.customImageUrl.isEmpty) return const SizedBox.shrink();
           
           return GestureDetector(
             onTap: () {
               try {
                 ref.read(adManagerProvider).handleCustomAdClick(bannerConfig.customTargetUrl);
               } catch (e) {
                 debugPrint('❌ Error handling custom ad click: $e');
               }
             },
             child: Container(
               height: 60, // Standard banner height
               width: double.infinity,
               margin: const EdgeInsets.symmetric(vertical: 8),
               child: CachedNetworkImage(
                 imageUrl: bannerConfig.customImageUrl,
                 fit: BoxFit.cover,
                 placeholder: (context, url) => Shimmer.fromColors(
                   baseColor: Colors.grey[300]!,
                   highlightColor: Colors.grey[100]!,
                   child: Container(color: Colors.white),
                 ),
                 errorWidget: (context, url, error) {
                   debugPrint('❌ Failed to load custom banner image: $error');
                   return const SizedBox.shrink();
                 },
               ),
             ),
           );
        }

        // AdMob
        if (bannerConfig.provider == 'admob') {
          if (bannerConfig.unitId.isEmpty) return const SizedBox.shrink();

          // Use test ad in debug mode
          final adUnitId = bannerConfig.getAdUnitId(kDebugMode, AdsConfig.testBannerAdUnitId);

          // Try loading ad if not yet loaded and no error
          if (!_isAdLoaded && !_hasError) {
            _loadAd(adUnitId);
          }

          // Show error in debug mode
          if (_hasError && kDebugMode) {
            return Container(
              height: 50,
              color: Colors.red.withOpacity(0.2),
              alignment: Alignment.center,
              child: const Text("Banner Ad Failed to Load", style: TextStyle(fontSize: 10)),
            );
          }

          if (_bannerAd != null && _isAdLoaded) {
             return Container(
               width: _bannerAd!.size.width.toDouble(),
               height: _bannerAd!.size.height.toDouble(),
               margin: const EdgeInsets.symmetric(vertical: 8),
               child: Stack(
                 children: [
                   AdWidget(ad: _bannerAd!),
                   if (kDebugMode)
                     Positioned(
                       top: 0,
                       right: 0,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         color: Colors.green,
                         child: const Text('TEST AD', style: TextStyle(color: Colors.white, fontSize: 8)),
                       ),
                     ),
                 ],
               ),
             );
          }
          
          // Ad is loading or failed, show nothing to avoid layout jumps
          return const SizedBox(height: 1); 
        }

        // Provider 'none' or unknown
        if (kDebugMode && config.globalEnabled && config.banner.enabled) {
           return Container(
             height: 50,
             color: Colors.red.withOpacity(0.2),
             alignment: Alignment.center,
             child: Text("Ad Config Error: Provider '${bannerConfig.provider}' unknown", style: const TextStyle(fontSize: 10)),
           );
        }
        return const SizedBox.shrink();
      },
      loading: () => kDebugMode 
          ? Container(
              height: 50, 
              color: Colors.blue.withOpacity(0.2), 
              alignment: Alignment.center, 
              child: const Text("Loading Ad Config...", style: TextStyle(fontSize: 10))
            ) 
          : const SizedBox.shrink(),
      error: (err, stack) {
        debugPrint("❌ Ad Config Error: $err");
        return kDebugMode 
          ? Container(
              height: 50, 
              color: Colors.red, 
              alignment: Alignment.center, 
              child: Text("Ad Config Error: $err", style: const TextStyle(color: Colors.white, fontSize: 10))
            ) 
          : const SizedBox.shrink();
      },
    );
  }
}
