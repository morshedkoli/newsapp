import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ads_config_model.dart';
import '../../data/repository/ads_repository.dart';

/// Provider for AdsRepository
final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return AdsRepository();
});

/// Provider for tracking interstitial ad display count
final interstitialCounterProvider = StateProvider<int>((ref) => 0);

/// Real-time Ads Configuration Provider
final adsConfigProvider = StreamProvider<AdsConfig>((ref) {
  final repository = ref.watch(adsRepositoryProvider);
  return repository.getAdsConfigStream();
});
