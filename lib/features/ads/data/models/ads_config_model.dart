/// Configuration for a specific ad position (banner, native, etc.)
class AdPositionConfig {
  final bool enabled;
  final String provider; // 'admob', 'custom', 'none'
  final String unitId;
  final String customImageUrl;
  final String customTargetUrl;
  final int frequency; // For native/interstitial

  AdPositionConfig({
    required this.enabled,
    required this.provider,
    required this.unitId,
    required this.customImageUrl,
    required this.customTargetUrl,
    required this.frequency,
  });

  factory AdPositionConfig.empty() {
    return AdPositionConfig(
      enabled: false,
      provider: 'none',
      unitId: '',
      customImageUrl: '',
      customTargetUrl: '',
      frequency: 5,
    );
  }

  factory AdPositionConfig.fromMap(Map<String, dynamic> map) {
    return AdPositionConfig(
      enabled: map['enabled'] as bool? ?? false,
      provider: map['provider'] as String? ?? 'none',
      unitId: map['unitId'] as String? ?? '',
      customImageUrl: map['customImageUrl'] as String? ?? '',
      customTargetUrl: map['customLinkUrl'] as String? ?? '', // Note key change
      frequency: map['frequency'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'provider': provider,
      'unitId': unitId,
      'customImageUrl': customImageUrl,
      'customLinkUrl': customTargetUrl,
      'frequency': frequency,
    };
  }
}

/// Main Ads Configuration
class AdsConfig {
  final bool globalEnabled;
  final AdPositionConfig banner;
  final AdPositionConfig native;
  final AdPositionConfig interstitial;

  AdsConfig({
    required this.globalEnabled,
    required this.banner,
    required this.native,
    required this.interstitial,
  });

  factory AdsConfig.defaultConfig() {
    return AdsConfig(
      globalEnabled: false,
      banner: AdPositionConfig.empty(),
      native: AdPositionConfig.empty(),
      interstitial: AdPositionConfig.empty(),
    );
  }

  /// Alias for defaultConfig
  factory AdsConfig.defaults() => AdsConfig.defaultConfig();

  factory AdsConfig.fromMap(Map<String, dynamic> map) {
    // Check if map is empty or null
    if (map.isEmpty) return AdsConfig.defaultConfig();

    return AdsConfig(
      globalEnabled: map['globalEnabled'] as bool? ?? false,
      banner: AdPositionConfig.fromMap(map['banner'] as Map<String, dynamic>? ?? {}),
      native: AdPositionConfig.fromMap(map['native'] as Map<String, dynamic>? ?? {}),
      interstitial: AdPositionConfig.fromMap(map['interstitial'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Alias for fromMap
  factory AdsConfig.fromJson(Map<String, dynamic> json) => AdsConfig.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'globalEnabled': globalEnabled,
      'banner': banner.toMap(),
      'native': native.toMap(),
      'interstitial': interstitial.toMap(),
    };
  }
}
