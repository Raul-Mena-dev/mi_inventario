import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _businessNameKey = "business_name";

  static Future<void> saveBusinessName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessNameKey, name);
  }

  static Future<String?> getBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_businessNameKey);
  }
}
