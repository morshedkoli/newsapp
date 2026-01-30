import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get supportsFirebase => isMobile || kIsWeb;
  static bool get supportsAds => isMobile;
}
