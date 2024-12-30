import 'package:shared_preferences/shared_preferences.dart';
import '../utils/shared_prefs.dart';

class AuthProvider {
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userId');
  }

  static Future<void> logout() async {
    await SharedPrefs.clearAllData();
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userData['id']);
    await prefs.setString('role', userData['role']);
    await prefs.setString('email', userData['email']);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}