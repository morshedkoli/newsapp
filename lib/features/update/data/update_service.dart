import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/utils/platform_utils.dart';

class UpdateConfig {
  final String latestVersion;
  final bool forceUpdate;
  final String updateMessage;
  final String playStoreUrl;

  UpdateConfig({
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateMessage,
    required this.playStoreUrl,
  });

  factory UpdateConfig.fromMap(Map<String, dynamic> map) {
    return UpdateConfig(
      latestVersion: map['latest_version'] ?? '1.0.0',
      forceUpdate: map['force_update'] ?? false,
      updateMessage: map['update_message'] ?? 'A new version is available.',
      playStoreUrl: map['play_store_url'] ?? '',
    );
  }
}

class UpdateService {
  // Use a getter to avoid instance access crash on unsupported platforms
  FirebaseFirestore? get _firestore => 
      PlatformUtils.supportsFirebase ? FirebaseFirestore.instance : null;

  Future<UpdateConfig?> checkUpdate() async {
    if (!PlatformUtils.supportsFirebase) {
      return null;
    }
    
    try {
      final firestore = _firestore;
      if (firestore == null) return null;

      // 1. Fetch Remote Config from Firestore
      final doc = await firestore.collection('app_config').doc('version').get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final config = UpdateConfig.fromMap(doc.data()!);

      // 2. Fetch Local App Version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 3. Compare Versions
      if (_isUpdateAvailable(currentVersion, config.latestVersion)) {
        return config;
      } else {
        return null; // No update needed
      }
    } catch (e) {
      // Fail silently if offline or error
      return null;
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int latestPart = latestParts[i];

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false;
    } catch (e) {
      return false; // Error parsing versions
    }
  }
}
