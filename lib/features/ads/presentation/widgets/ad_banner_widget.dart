import 'package:flutter/material.dart';
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

  void _loadAd(String unitId) {
    if (_bannerAd != null) return; // Already loaded

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
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Platform Check: Don't show ads if not supported
    if (!PlatformUtils.supportsAds) {
      return const SizedBox.shrink();
    }

    final adsConfigAsync = ref.watch(adsConfigProvider);

    return adsConfigAsync.when(
      data: (config) {
        // Global switch check
        if (!config.globalEnabled || !config.banner.enabled) {
          return const SizedBox.shrink();
        }

        final bannerConfig = config.banner;

        // Custom Ad
        if (bannerConfig.provider == 'custom') {
           if (bannerConfig.customImageUrl.isEmpty) return const SizedBox.shrink();
           
           return GestureDetector(
             onTap: () => ref.read(adManagerProvider).handleCustomAdClick(bannerConfig.customTargetUrl),
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
                 errorWidget: (context, url, error) => const SizedBox.shrink(),
               ),
             ),
           );
        }

        // AdMob
        if (bannerConfig.provider == 'admob') {
          if (bannerConfig.unitId.isEmpty) return const SizedBox.shrink();

          // Try loading ad if not yet loaded
          if (!_isAdLoaded) {
            _loadAd(bannerConfig.unitId);
          }

          if (_bannerAd != null && _isAdLoaded) {
             return Container(
               width: _bannerAd!.size.width.toDouble(),
               height: _bannerAd!.size.height.toDouble(),
               margin: const EdgeInsets.symmetric(vertical: 8),
               child: AdWidget(ad: _bannerAd!),
             );
          }
          
          // Ad is loading or failed, show nothing or placeholder? 
          // Better to show nothing until loaded to avoid layout jumps
          return const SizedBox(height: 1); 
        }

        // Provider 'none' or unknown
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
