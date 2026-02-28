import 'package:flutter/material.dart';

/// Premium streaming-app theme (MYTVOnline+-style dark theme).
/// Use [AppTheme.dark] for the app and [AppTheme.darkColorScheme] for overrides.
class AppTheme {
  AppTheme._();

  static const Color _surfaceDark = Color(0xFF0D0D0D);
  static const Color _surfaceVariant = Color(0xFF1A1A1A);
  static const Color _surfaceCard = Color(0xFF1E1E1E);
  static const Color _onSurface = Color(0xFFF5F5F5);
  static const Color _onSurfaceVariant = Color(0xFFB0B0B0);
  static const Color _primary = Color(0xFFE50914);
  static const Color _primaryVariant = Color(0xFFB20710);
  static const Color _outline = Color(0xFF404040);

  static ColorScheme get darkColorScheme {
    return const ColorScheme.dark(
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: _primaryVariant,
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF2E7BF5),
      onSecondary: Colors.white,
      surface: _surfaceDark,
      onSurface: _onSurface,
      surfaceContainerHighest: _surfaceVariant,
      onSurfaceVariant: _onSurfaceVariant,
      outline: _outline,
      error: Color(0xFFCF6679),
      onError: Colors.black,
    );
  }

  static ThemeData get dark {
    final colorScheme = darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      ),
      cardTheme: CardThemeData(
        color: _surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.compact,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: _onSurfaceVariant, fontSize: 15),
        labelStyle: TextStyle(color: _onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textTheme: _textTheme(colorScheme),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceVariant,
        labelStyle: const TextStyle(color: _onSurface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      headlineSmall: TextStyle(
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: scheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: scheme.onSurface, fontSize: 16),
      bodyMedium: TextStyle(color: scheme.onSurface, fontSize: 14),
      bodySmall: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      labelLarge: TextStyle(
        color: scheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
