import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  bool _hasError = false;

  void _loadAd(String unitId) {
    if (_nativeAd != null || _hasError) return;

    try {
      NativeAd(
        adUnitId: unitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _nativeAd = ad as NativeAd;
                _isAdLoaded = true;
                _hasError = false;
              });
              debugPrint('✅ Native ad loaded successfully');
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ Native ad failed to load: $error');
            ad.dispose();
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
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
    } catch (e) {
      debugPrint('❌ Exception loading native ad: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
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
            onTap: () {
              try {
                ref.read(adManagerProvider).handleCustomAdClick(nativeConfig.customTargetUrl);
              } catch (e) {
                debugPrint('❌ Error handling custom native ad click: $e');
              }
            },
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
                          errorWidget: (_, __, error) {
                            debugPrint('❌ Failed to load custom native ad image: $error');
                            return const SizedBox.shrink();
                          },
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
          
          // Use test ad in debug mode
          final adUnitId = nativeConfig.getAdUnitId(kDebugMode, AdsConfig.testNativeAdUnitId);
          
          if (!_isAdLoaded && !_hasError) {
            _loadAd(adUnitId);
          }

          // Show error in debug mode
          if (_hasError && kDebugMode) {
            return Container(
              height: 100,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.red.withOpacity(0.2),
              alignment: Alignment.center,
              child: const Text("Native Ad Failed to Load", style: TextStyle(fontSize: 10)),
            );
          }

          if (_nativeAd != null && _isAdLoaded) {
             return Container(
               height: 320, // Typical height for medium template
               margin: const EdgeInsets.symmetric(vertical: 8),
               child: Stack(
                 children: [
                   AdWidget(ad: _nativeAd!),
                   if (kDebugMode)
                     Positioned(
                       top: 8,
                       right: 8,
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
           return const SizedBox(height: 1); 
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) {
        debugPrint('❌ Native ad config error: $err');
        return const SizedBox.shrink();
      },
    );
  }
}
