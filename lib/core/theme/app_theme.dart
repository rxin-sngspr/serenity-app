import 'package:flutter/material.dart';
import 'palette.dart';
import 'typography.dart';

enum AppTheme { rose, sage, ocean, terracotta, lavender }

class AppThemeData {
  AppThemeData._();

  static ThemeData getTheme({
    required AppTheme theme,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    Color bg, card, border, text, textSecondary, primary, primaryVariant, tertiary;

    switch (theme) {
      case AppTheme.rose:
        bg = isDark ? WarmRosePalette.darkBg : WarmRosePalette.lightBg;
        card = isDark ? WarmRosePalette.darkCard : WarmRosePalette.lightCard;
        border = isDark ? WarmRosePalette.darkBorder : WarmRosePalette.lightBorder;
        text = isDark ? WarmRosePalette.darkText : WarmRosePalette.lightText;
        textSecondary = isDark ? WarmRosePalette.darkTextSecondary : WarmRosePalette.lightTextSecondary;
        primary = WarmRosePalette.primary;
        primaryVariant = WarmRosePalette.primaryVariant;
        tertiary = WarmRosePalette.accent;
      case AppTheme.sage:
        bg = isDark ? SagePalette.darkBg : SagePalette.lightBg;
        card = isDark ? SagePalette.darkCard : SagePalette.lightCard;
        border = isDark ? SagePalette.darkBorder : SagePalette.lightBorder;
        text = isDark ? SagePalette.darkText : SagePalette.lightText;
        textSecondary = isDark ? SagePalette.darkTextSecondary : SagePalette.lightTextSecondary;
        primary = SagePalette.primary;
        primaryVariant = SagePalette.primaryVariant;
        tertiary = SagePalette.accent;
      case AppTheme.ocean:
        bg = isDark ? OceanPalette.darkBg : OceanPalette.lightBg;
        card = isDark ? OceanPalette.darkCard : OceanPalette.lightCard;
        border = isDark ? OceanPalette.darkBorder : OceanPalette.lightBorder;
        text = isDark ? OceanPalette.darkText : OceanPalette.lightText;
        textSecondary = isDark ? OceanPalette.darkTextSecondary : OceanPalette.lightTextSecondary;
        primary = OceanPalette.primary;
        primaryVariant = OceanPalette.primaryVariant;
        tertiary = OceanPalette.accent;
      case AppTheme.terracotta:
        bg = isDark ? TerracottaPalette.darkBg : TerracottaPalette.lightBg;
        card = isDark ? TerracottaPalette.darkCard : TerracottaPalette.lightCard;
        border = isDark ? TerracottaPalette.darkBorder : TerracottaPalette.lightBorder;
        text = isDark ? TerracottaPalette.darkText : TerracottaPalette.lightText;
        textSecondary = isDark ? TerracottaPalette.darkTextSecondary : TerracottaPalette.lightTextSecondary;
        primary = TerracottaPalette.primary;
        primaryVariant = TerracottaPalette.primaryVariant;
        tertiary = TerracottaPalette.accent;
      case AppTheme.lavender:
        bg = isDark ? LavenderPalette.darkBg : LavenderPalette.lightBg;
        card = isDark ? LavenderPalette.darkCard : LavenderPalette.lightCard;
        border = isDark ? LavenderPalette.darkBorder : LavenderPalette.lightBorder;
        text = isDark ? LavenderPalette.darkText : LavenderPalette.lightText;
        textSecondary = isDark ? LavenderPalette.darkTextSecondary : LavenderPalette.lightTextSecondary;
        primary = LavenderPalette.primary;
        primaryVariant = LavenderPalette.primaryVariant;
        tertiary = LavenderPalette.accent;
    }

    // Translucent border for surfaceContainerHighest
    final borderWithAlpha = border.withAlpha(77);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primaryVariant,
      onSecondary: Colors.white,
      tertiary: tertiary,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: card,
      onSurface: text,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border.withAlpha(128),
      surfaceContainerHighest: borderWithAlpha,
      surfaceTint: primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: AppTypography.getTextTheme().apply(
        bodyColor: text,
        displayColor: text,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary,
        labelStyle: AppTypography.getTextTheme().labelSmall?.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
    );
  }
}
