import 'package:flutter/material.dart';

/// Serenity typography system.
///
/// Three typefaces:
/// - Plus Jakarta Sans: headings (300, 400, 500, 600, 700 + italic)
/// - Inter: body text (300, 400, 500)
/// - Cormorant Garamond: editorial/reflective text (300, 400, 500, 600, 700 + italic)
class AppTypography {
  AppTypography._();

  static TextTheme getTextTheme() {
    return TextTheme(
      // Display 40/48 — Plus Jakarta Sans 700
      displayLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),

      // H1 32/40 — Plus Jakarta Sans 600
      headlineLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),

      // H2 28/36 — Plus Jakarta Sans 600
      headlineMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.286,
      ),

      // H3 22/30 — Plus Jakarta Sans 500
      headlineSmall: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.364,
      ),

      // H4 18/26 — Plus Jakarta Sans 500
      titleLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.444,
      ),

      // Body 16/24 — Inter 400
      bodyLarge: TextStyle(fontFamily: 'Inter', 
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),

      // Body Small 14/22 — Inter 400
      bodyMedium: TextStyle(fontFamily: 'Inter', 
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.571,
      ),

      // Caption 12/18 — Inter 400
      bodySmall: TextStyle(fontFamily: 'Inter', 
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),

      // Label styles for UI elements
      labelLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      labelMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
      ),
      labelSmall: TextStyle(fontFamily: 'Plus Jakarta Sans', 
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.4,
      ),
    );
  }
}

/// Custom text styles outside the Material scale.
///
/// These are used for editorial/reflective content throughout the app.
class SerenityTextStyles {
  SerenityTextStyles._();

  /// Editorial Quote — Cormorant Garamond 22px/30px weight 300 italic
  static TextStyle editorialQuote(BuildContext context) {
    return TextStyle(fontFamily: 'Cormorant Garamond', 
      fontSize: 22,
      height: 30 / 22,
      fontWeight: FontWeight.w300,
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// Editorial Body — Cormorant Garamond 16px/24px weight 400 italic
  static TextStyle editorialBody(BuildContext context) {
    return TextStyle(fontFamily: 'Cormorant Garamond', 
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
