import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _businessNameKey = "business_name";
  static const _logoPathKey = "business_logo";
  static const _facebookKey = "facebook_url";
  static const _instagramKey = "instagram_url";
  static const _tiktokKey = "tiktok_url";
  static const _xKey = "x_url";
  static const _whatsappKey = "whatsapp_url";
  static const _languageCodeKey = "language_code";
  static const _themeKey = "app_theme";
  static const _tutorialCompletedKey = "tutorial_completed";

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

  static Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, code);
  }

  static Future<void> saveThemeKey(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  static Future<void> saveTutorialCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, completed);
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

  static Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCodeKey) ?? "es";
  }

  static Future<String> getThemeKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? "classic";
  }

  static Future<bool> getTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  static Future<Map<String, dynamic>> exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "businessName": prefs.getString(_businessNameKey) ?? "",
      "logoPath": prefs.getString(_logoPathKey) ?? "",
      "socialLinks": await getSocialLinks(),
      "languageCode": await getLanguageCode(),
      "themeKey": await getThemeKey(),
      "tutorialCompleted": await getTutorialCompleted(),
    };
  }

  static Future<void> importSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _businessNameKey,
      (settings["businessName"] ?? "") as String,
    );
    await prefs.setString(
      _languageCodeKey,
      (settings["languageCode"] ?? "es") as String,
    );
    await prefs.setString(
      _themeKey,
      (settings["themeKey"] ?? "classic") as String,
    );
    await prefs.setBool(
      _tutorialCompletedKey,
      (settings["tutorialCompleted"] as bool?) ?? false,
    );
    final logoPath = (settings["logoPath"] ?? "") as String;
    if (logoPath.isNotEmpty) await prefs.setString(_logoPathKey, logoPath);

    final links = settings["socialLinks"];
    if (links is Map) {
      await saveSocialLinks(
        facebook: (links["facebook"] ?? "") as String,
        instagram: (links["instagram"] ?? "") as String,
        tiktok: (links["tiktok"] ?? "") as String,
        x: (links["x"] ?? "") as String,
        whatsapp: (links["whatsapp"] ?? "") as String,
      );
    }
  }

  static String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
