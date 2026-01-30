import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/platform_utils.dart';
import '../providers/ads_provider.dart';
import '../managers/ad_manager.dart';
import '../../data/models/ads_config_model.dart';
import '../../../../core/theme/app_theme.dart';

class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  void _loadAd(String unitId) {
    if (_nativeAd != null) return;

    NativeAd(
      adUnitId: unitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd;
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppTheme.primaryColor,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
      ),
    ).load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Platform Check
    if (!PlatformUtils.supportsAds) {
      return const SizedBox.shrink();
    }

    final adsConfigAsync = ref.watch(adsConfigProvider);

    return adsConfigAsync.when(
      data: (config) {
        if (!config.globalEnabled || !config.native.enabled) {
          return const SizedBox.shrink();
        }

        final nativeConfig = config.native;

        // Custom Native Ad
        if (nativeConfig.provider == 'custom') {
          if (nativeConfig.customImageUrl.isEmpty) return const SizedBox.shrink();
          
          return GestureDetector(
            onTap: () => ref.read(adManagerProvider).handleCustomAdClick(nativeConfig.customTargetUrl),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: nativeConfig.customImageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sponsored',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // AdMob Native Ad
        if (nativeConfig.provider == 'admob') {
          if (nativeConfig.unitId.isEmpty) return const SizedBox.shrink();
          
          if (!_isAdLoaded) {
            _loadAd(nativeConfig.unitId);
          }

          if (_nativeAd != null && _isAdLoaded) {
             return Container(
               height: 320, // Typical height for medium template
               margin: const EdgeInsets.symmetric(vertical: 8),
               child: AdWidget(ad: _nativeAd!),
             );
          }
           return const SizedBox(height: 1); 
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
