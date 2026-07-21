import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/repositories/reminder_repository.dart';
import 'services/app_preferences.dart';
import 'services/app_themes.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/tutorial_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.instance.load();
  await NotificationService.initialize();
  final showTutorial = !await SettingsService.getTutorialCompleted();
  final reminders = await ReminderRepository.getPendingReminders();
  for (final reminder in reminders) {
    await NotificationService.scheduleReminder(reminder);
  }
  runApp(MyApp(showTutorial: showTutorial));
}

class MyApp extends StatelessWidget {
  final bool showTutorial;

  const MyApp({
    super.key,
    required this.showTutorial,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppPreferences.instance,
      builder: (context, _) {
        final option = AppThemes.optionFor(AppPreferences.instance.themeKey);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Inventario',
          locale: AppPreferences.instance.locale,
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppThemes.lightTheme(option.seedColor),
          darkTheme: AppThemes.darkTheme(option.seedColor),
          themeMode: option.mode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.0),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: SplashScreen(
            next: showTutorial ? const TutorialScreen() : const HomeScreen(),
          ),
        );
      },
    );
  }
}
