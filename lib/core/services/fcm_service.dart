import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../utils/app_router.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 0. Background handler is now in main.dart

    // 1. Request Permission
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 1.1 Subscribe to Topics (Multiple to be safe)
    // We do this REGARDLESS of current permission status to ensure registration
    // The OS will block display if permission is denied, but subscription should happen.
    await _messaging.subscribeToTopic('news');
    await _messaging.subscribeToTopic('all'); 
    await _messaging.subscribeToTopic('general');
    debugPrint('Subscribed to topics: news, all, general');

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
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
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

