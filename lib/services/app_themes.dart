import 'package:flutter/material.dart';

class AppThemeOption {
  final String key;
  final String label;
  final Color seedColor;
  final ThemeMode mode;

  const AppThemeOption({
    required this.key,
    required this.label,
    required this.seedColor,
    required this.mode,
  });
}

class AppThemes {
  static const options = [
    AppThemeOption(
      key: 'classic',
      label: 'Clásico',
      seedColor: Colors.blue,
      mode: ThemeMode.light,
    ),
    AppThemeOption(
      key: 'green',
      label: 'Verde negocio',
      seedColor: Colors.green,
      mode: ThemeMode.light,
    ),
    AppThemeOption(
      key: 'purple',
      label: 'Morado',
      seedColor: Colors.deepPurple,
      mode: ThemeMode.light,
    ),
    AppThemeOption(
      key: 'dark',
      label: 'Oscuro',
      seedColor: Colors.teal,
      mode: ThemeMode.dark,
    ),
  ];

  static AppThemeOption optionFor(String key) {
    return options.firstWhere(
      (option) => option.key == key,
      orElse: () => options.first,
    );
  }

  static ThemeData lightTheme(Color seedColor) {
    return _baseTheme(
      ColorScheme.fromSeed(seedColor: seedColor),
    );
  }

  static ThemeData darkTheme(Color seedColor) {
    return _baseTheme(
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.compact,
      hintColor: isDark ? colorScheme.onSurface.withValues(alpha: 0.72) : null,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : colorScheme.surface,
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.82),
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.68),
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.75 : 1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minLeadingWidth: 28,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHighest,
        textStyle: TextStyle(color: colorScheme.onSurface),
        iconColor: colorScheme.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
