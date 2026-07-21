import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static const int maxAdsPerDay = 3;
  static const Duration interstitialCooldown = Duration(hours: 4);
  static const _dateKey = 'ads_date';
  static const _countKey = 'ads_count';
  static const _lastInterstitialKey = 'ads_last_interstitial';
  static const _appOpenDateKey = 'ads_app_open_date';

  static Future<bool> consumeBannerImpression(String placement) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    final today = _todayKey();
    final placementKey = 'ads_banner_${placement}_$today';
    if (prefs.getBool(placementKey) ?? false) return false;
    if (!_hasDailyAvailability(prefs)) return false;
    await prefs.setBool(placementKey, true);
    await _incrementCount(prefs);
    return true;
  }

  static Future<void> maybeShowAppOpenAd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    final today = _todayKey();
    if (prefs.getString(_appOpenDateKey) == today) return;
    if (!_hasDailyAvailability(prefs)) return;
    await prefs.setString(_appOpenDateKey, today);
    await _incrementCount(prefs);
    if (!context.mounted) return;
    await showMockInterstitial(
      context,
      title: 'Anuncio de prueba',
      message: 'Aquí se mostraría un anuncio al abrir la app.',
      alreadyConsumed: true,
    );
  }

  static Future<void> maybeShowInterstitial(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    if (!_hasDailyAvailability(prefs)) return;

    final lastValue = prefs.getString(_lastInterstitialKey);
    final last = lastValue == null ? null : DateTime.tryParse(lastValue);
    if (last != null &&
        DateTime.now().difference(last) < interstitialCooldown) {
      return;
    }

    await prefs.setString(
        _lastInterstitialKey, DateTime.now().toIso8601String());
    await _incrementCount(prefs);
    if (!context.mounted) return;
    await showMockInterstitial(
      context,
      title: title,
      message: message,
      alreadyConsumed: true,
    );
  }

  static Future<void> showMockInterstitial(
    BuildContext context, {
    required String title,
    required String message,
    bool alreadyConsumed = false,
  }) async {
    if (!alreadyConsumed) {
      final prefs = await SharedPreferences.getInstance();
      await _resetIfNeeded(prefs);
      if (!_hasDailyAvailability(prefs)) return;
      await _incrementCount(prefs);
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 8),
            const Text(
              'Modo prueba: aquí irá AdMob cuando agregues tus llaves.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static Future<void> _resetIfNeeded(SharedPreferences prefs) async {
    final today = _todayKey();
    if (prefs.getString(_dateKey) == today) return;
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_countKey, 0);
  }

  static bool _hasDailyAvailability(SharedPreferences prefs) {
    return (prefs.getInt(_countKey) ?? 0) < maxAdsPerDay;
  }

  static Future<void> _incrementCount(SharedPreferences prefs) async {
    await prefs.setInt(_countKey, (prefs.getInt(_countKey) ?? 0) + 1);
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
