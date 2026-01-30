import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../utils/app_router.dart';
import '../utils/platform_utils.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

class FcmService {
  // Accessing instance might throw if not initialized, so we use a getter or late final with check,
  // but safest is to just check before use.
  FirebaseMessaging? get _messaging => 
      PlatformUtils.supportsFirebase ? FirebaseMessaging.instance : null;

  Future<void> initialize() async {
    if (!PlatformUtils.supportsFirebase) return;
    
    final messaging = _messaging;
    if (messaging == null) return;

    // 0. Background handler is now in main.dart

    // 1. Request Permission
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 1.1 Subscribe to Topics (Multiple to be safe)
    if (!kIsWeb) {
      try {
        await messaging.subscribeToTopic('news');
        await messaging.subscribeToTopic('all');
        await messaging.subscribeToTopic('general');
        debugPrint('Subscribed to topics: news, all, general');
      } catch (e) {
        debugPrint('Failed to subscribe to topics: $e');
      }
    }

    // 2. Setup Foreground Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground Message: ${message.notification?.title}");
      
      // Show local notification if needed (logic omitted for simplicity, but basic print added)
      if (message.notification != null) {
         // Ideally, use flutter_local_notifications here to show a dialog/snackbar
         // For now, we rely on the OS for background, but at least we log it.
      }
    });

    // 3. Setup Initial Message Handler (App opened from terminated state)
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 4. Setup Message Opened App Handler (App opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint("Handling Message Navigation: ${message.data}");
    if (message.data.containsKey('newsId')) {
      final newsId = message.data['newsId'];
      goRouter.push('/news/$newsId');
    } else if (message.data['type'] == 'news') {
      goRouter.push(AppConstants.newsReaderRoute); 
    }
  }
}

// Top-level function for background handling

