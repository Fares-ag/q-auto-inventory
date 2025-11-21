import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color brandPrimary = Color(0xFF0C2D57);
  static const Color brandAccent = Color(0xFF1B9AAA);
  static const Color brandSuccess = Color(0xFF16A34A);
  static const Color brandWarning = Color(0xFFF59E0B);
  static const Color brandError = Color(0xFFDC2626);

  // Neutrals
  static const Color neutralText = Color(0xFF0F172A);
  static const Color neutralTextSecondary = Color(0xFF475569);
  static const Color neutralDisabled = Color(0xFF94A3B8);
  static const Color neutralBorder = Color(0xFFE2E8F0);
  static const Color neutralBg = Color(0xFFF8FAFC);

  static final ThemeData light = _buildLightTheme();
  static final ThemeData dark = _buildDarkTheme();

  static TextTheme _textTheme({required Brightness brightness}) {
    // Typography scale: 32/24/20/16/14/12; headings 600, body 400
    final bool isDark = brightness == Brightness.dark;
    final Color bodyColor = isDark ? const Color(0xFFE5E7EB) : neutralText;
    final Color secondaryColor = isDark ? const Color(0xFF9CA3AF) : neutralTextSecondary;

    return TextTheme(
      displaySmall: TextStyle( // H1 ~ 32
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: bodyColor,
      ),
      headlineMedium: TextStyle( // H2 ~ 24
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: bodyColor,
      ),
      headlineSmall: TextStyle( // H3 ~ 20
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: bodyColor,
      ),
      titleMedium: TextStyle( // Title ~ 16
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: bodyColor,
      ),
      bodyLarge: TextStyle( // Body 16
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: bodyColor,
      ),
      bodyMedium: TextStyle( // Body 14
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: bodyColor,
      ),
      bodySmall: TextStyle( // Caption 12
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: secondaryColor,
      ),
      labelLarge: const TextStyle( // Buttons
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }

  static ColorScheme _lightScheme() {
    return ColorScheme(
      brightness: Brightness.light,
      primary: brandPrimary,
      onPrimary: Colors.white,
      secondary: brandAccent,
      onSecondary: Colors.white,
      error: brandError,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: neutralText,
      tertiary: brandSuccess,
      onTertiary: Colors.white,
      primaryContainer: brandPrimary.withOpacity(0.08),
      onPrimaryContainer: brandPrimary,
      secondaryContainer: brandAccent.withOpacity(0.08),
      onSecondaryContainer: brandAccent,
      surfaceContainerHighest: neutralBg,
      outline: neutralBorder,
      outlineVariant: neutralBorder,
      scrim: Colors.black.withOpacity(0.5),
    );
  }

  static ThemeData _buildLightTheme() {
    final colorScheme = _lightScheme();
    final textTheme = _textTheme(brightness: Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: neutralBg,
      fontFamily: null, // system fonts (Inter/SF Pro fallback not bundled)
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppTheme._lightAppBarTheme(textTheme),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ).merge(ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? colorScheme.onPrimary.withOpacity(0.10)
                : null,
          ),
        )),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: const BorderSide(color: neutralBorder, width: 1),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.transparent,
        ).merge(ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? colorScheme.primary.withOpacity(0.08)
                : null,
          ),
        )),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ).merge(ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? colorScheme.primary.withOpacity(0.10)
                : null,
          ),
        )),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neutralBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neutralBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandError, width: 2),
        ),
        labelStyle: const TextStyle(color: neutralTextSecondary),
        helperStyle: const TextStyle(fontSize: 12, color: neutralTextSecondary),
        errorStyle: const TextStyle(fontSize: 12, color: brandError),
      ),

      // Chips/Tags
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: brandAccent.withOpacity(0.15),
        labelStyle: const TextStyle(fontSize: 12),
        side: const BorderSide(color: neutralBorder),
      ),

      // Tabs
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: neutralTextSecondary,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: brandAccent, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 16),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: neutralBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: neutralBorder,
        thickness: 1,
        space: 24,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        iconColor: neutralTextSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Snackbars/Toasts
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neutralText,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Focus ring for accessibility
      focusColor: brandAccent.withOpacity(0.12),
      hoverColor: brandAccent.withOpacity(0.06),
      highlightColor: brandAccent.withOpacity(0.06),
    );
  }

  static ThemeData _buildDarkTheme() {
    // Dark mode spec
    const Color darkBg = Color(0xFF0B1220);
    const Color darkCard = Color(0xFF111827);
    const Color darkText = Color(0xFFE5E7EB);

    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: brandPrimary,
      onPrimary: Colors.white,
      secondary: brandAccent,
      onSecondary: Colors.white,
      error: brandError,
      onError: Colors.white,
      surface: darkCard,
      onSurface: darkText,
      tertiary: brandSuccess,
      onTertiary: Colors.white,
      primaryContainer: Color(0xFF0C2D57),
      onPrimaryContainer: Colors.white,
      secondaryContainer: Color(0xFF1B9AAA),
      onSecondaryContainer: Colors.white,
      surfaceContainerHighest: darkBg,
      outline: Color(0xFF374151),
      outlineVariant: Color(0xFF1F2937),
      scrim: Colors.black54,
    );

    final textTheme = _textTheme(brightness: Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      fontFamily: null,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppTheme._darkAppBarTheme(textTheme),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: const BorderSide(color: Color(0xFF374151), width: 1),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandError, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        helperStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        errorStyle: const TextStyle(fontSize: 12, color: brandError),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: brandAccent.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 12, color: darkText),
        side: const BorderSide(color: Color(0xFF374151)),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: brandAccent,
        unselectedLabelColor: Color(0xFF9CA3AF),
        indicatorColor: brandAccent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1F2937)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1F2937),
        thickness: 1,
        space: 24,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        iconColor: Color(0xFF9CA3AF),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: neutralText,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: darkCard,
      ),

      focusColor: brandAccent.withOpacity(0.16),
      hoverColor: brandAccent.withOpacity(0.10),
      highlightColor: brandAccent.withOpacity(0.10),
    );
  }

  // Minimal app bar themes
  static AppBarTheme _lightAppBarTheme(TextTheme text) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: neutralText,
      titleTextStyle: text.titleMedium,
      centerTitle: false,
    );
  }

  static AppBarTheme _darkAppBarTheme(TextTheme text) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: const Color(0xFFE5E7EB),
      titleTextStyle: text.titleMedium,
      centerTitle: false,
    );
  }
}
