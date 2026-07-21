import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _businessNameKey = "business_name";
  static const _logoPathKey = "business_logo";
  static const _facebookKey = "facebook_url";
  static const _instagramKey = "instagram_url";
  static const _tiktokKey = "tiktok_url";
  static const _xKey = "x_url";
  static const _whatsappKey = "whatsapp_url";

  // ======== SAVE METHODS ========
  static Future<void> saveBusinessName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_businessNameKey, _clean(name));
  }

  static Future<void> saveLogoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logoPathKey, path);
  }

  static Future<void> saveSocialLinks({
    String? facebook,
    String? instagram,
    String? tiktok,
    String? x,
    String? whatsapp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (facebook != null) await prefs.setString(_facebookKey, _clean(facebook));
    if (instagram != null) {
      await prefs.setString(_instagramKey, _clean(instagram));
    }
    if (tiktok != null) await prefs.setString(_tiktokKey, _clean(tiktok));
    if (x != null) await prefs.setString(_xKey, _clean(x));
    if (whatsapp != null) await prefs.setString(_whatsappKey, _clean(whatsapp));
  }

  // ======== GET METHODS ========
  static Future<String?> getBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_businessNameKey);
  }

  static Future<String?> getLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_logoPathKey);
  }

  static Future<Map<String, String>> getSocialLinks() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "facebook": prefs.getString(_facebookKey) ?? "",
      "instagram": prefs.getString(_instagramKey) ?? "",
      "tiktok": prefs.getString(_tiktokKey) ?? "",
      "x": prefs.getString(_xKey) ?? "",
      "whatsapp": prefs.getString(_whatsappKey) ?? "",
    };
  }

  static String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
