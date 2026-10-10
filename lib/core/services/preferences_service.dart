import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static SharedPreferences? _prefs;

  // Initialize once (usually in main.dart)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Keys ---
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyRememberMe = 'remember_me';
  static const String keySavedEmail = 'saved_email';
  static const String keySavedPassword = 'saved_password';

  // --- String Methods ---
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  // --- Boolean Methods ---
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  // --- Integer / Double Methods ---
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  // --- Delete / Clear ---
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }

  // Save credentials
Future<void> saveCredentials({
  required String email,
  required String password,
  bool rememberMe = true,
}) async {
  await setString(keySavedEmail, email);
  await setString(keySavedPassword, password);
  await setBool(keyRememberMe, rememberMe);
}
// Get saved credentials
String? getSavedEmail() => getString(keySavedEmail);
String? getSavedPassword() => getString(keySavedPassword);
bool isRememberMe() => getBool(keyRememberMe, defaultValue: false);

// Clear credentials (if user unchecks Remember Me or logs out)
Future<void> clearCredentials() async {
  await remove(keySavedEmail);
  await remove(keySavedPassword);
  await setBool(keyRememberMe, false);
}
}
