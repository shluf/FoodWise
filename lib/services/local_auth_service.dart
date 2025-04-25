import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userIdKey = 'userId';

  static Future<void> saveLoginStatus({required bool isLoggedIn, String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    } else if (!isLoggedIn) {
      await prefs.remove(_userIdKey);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userIdKey);
  }
}