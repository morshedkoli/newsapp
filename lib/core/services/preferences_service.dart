import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('PreferencesService must be overridden in main');
});

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyLastReadIndex = 'last_read_index';
  static const String _keySwipeTutorialShown = 'swipe_tutorial_shown';

  // First Launch
  bool get isFirstLaunch => _prefs.getBool(_keyIsFirstLaunch) ?? true;
  
  Future<void> setFirstLaunchDone() async {
    await _prefs.setBool(_keyIsFirstLaunch, false);
  }

  // Last Read Persistence
  int get lastReadIndex => _prefs.getInt(_keyLastReadIndex) ?? 0;

  Future<void> setLastReadIndex(int index) async {
    await _prefs.setInt(_keyLastReadIndex, index);
  }

  // Swipe Tutorial
  bool get isSwipeTutorialShown => _prefs.getBool(_keySwipeTutorialShown) ?? false;

  Future<void> setSwipeTutorialShown() async {
    await _prefs.setBool(_keySwipeTutorialShown, true);
  }

  // Push Permission
  static const String _keyPushPermissionAsked = 'push_permission_asked';
  bool get isPushPermissionAsked => _prefs.getBool(_keyPushPermissionAsked) ?? false;

  Future<void> setPushPermissionAsked() async {
    await _prefs.setBool(_keyPushPermissionAsked, true);
  }
}
