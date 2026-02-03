import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // Force rebuild
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/fcm_service.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/utils/platform_utils.dart';
import 'firebase_options.dart';
import 'features/ads/presentation/services/ads_initialization_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformUtils.supportsFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
     // Register background handler early ONLY if Firebase is supported
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // NOTE: AdMob SDK initialization moved to post-frame callback
  // to wait for ads config and only initialize if ads are enabled
  
  // Initialize Local Storage
  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
      ],
      child: const NewsByteApp(),
    ),
  );
}

class NewsByteApp extends ConsumerStatefulWidget {
  const NewsByteApp({super.key});

  @override
  ConsumerState<NewsByteApp> createState() => _NewsByteAppState();
}

class _NewsByteAppState extends ConsumerState<NewsByteApp> {
  @override
  void initState() {
    super.initState();
    // Initialize services after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (PlatformUtils.supportsFirebase) {
        ref.read(fcmServiceProvider).initialize();
      }
      
      // Conditionally initialize AdMob SDK based on config
      if (PlatformUtils.supportsAds) {
        ref.read(adsInitializationServiceProvider).initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NewsByte',
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (PlatformUtils.supportsFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint("Handling a background message IN MAIN: ${message.messageId}");
  }
}
