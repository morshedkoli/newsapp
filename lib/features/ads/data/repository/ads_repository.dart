import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/platform_utils.dart';
import '../models/ads_config_model.dart';

class AdsRepository {
  final FirebaseFirestore? _firestore;

  AdsRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? (PlatformUtils.supportsFirebase ? FirebaseFirestore.instance : null);

  /// Listen to real-time updates of ads configuration
  Stream<AdsConfig> getAdsConfigStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(AdsConfig.defaultConfig());
    }

    return firestore
        .collection('system_ads')
        .doc('config')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return AdsConfig.fromMap(snapshot.data()!);
          }
          return AdsConfig.defaultConfig();
        });
  }
}
