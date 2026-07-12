import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Premium monochrome ───────────────────────────────────────────────────
  // Pure black-and-white but designed with the rules that make B&W look
  // expensive instead of flat: never-pure-black ink, multi-stop neutral
  // ramp, soft-shadowed elevation instead of hard borders, and dramatic
  // typography weight contrast. Inspired by Vercel, Linear, Stripe (mono),
  // and Apple Pro marketing.

  // Ink — primary "color" of the entire UI. #0A0A0A reads as black but
  // softens harsh contrast that pure #000 produces on retina screens.
  static const Color primary = Color(0xFF0A0A0A);          // soft black
  static const Color primaryLight = Color(0xFF1F1F1F);     // hover
  static const Color primaryDark = Color(0xFF000000);      // active/press
  // Nav/tab pill + subtle fills — very light so UI stays white-dominant.
  static const Color primaryContainer = Color(0xFFF2F2F7);

  // Secondary — graphite (mid-weight ink for subtitles and supporting UI).
  static const Color secondary = Color(0xFF404040);
  static const Color secondaryLight = Color(0xFF737373);
  static const Color secondaryContainer = Color(0xFFFAFAFA);

  // ── Semantic colours ─────────────────────────────────────────────────────
  // Kept very muted — they read as "almost grayscale" on first glance but
  // remain distinguishable enough for status indication. Bloomberg-terminal
  // school of design.
  static const Color success = Color(0xFF14532D);           // forest green-900
  static const Color successContainer = Color(0xFFF0FDF4);  // green-50 wash
  static const Color onSuccess = Colors.white;

  static const Color warning = Color(0xFF78350F);           // dark amber-900
  static const Color warningContainer = Color(0xFFFFFBEB);  // amber-50 wash
  static const Color onWarning = Colors.white;

  static const Color error = Color(0xFF991B1B);             // dark red-800
  static const Color errorContainer = Color(0xFFFEF2F2);    // red-50 wash
  static const Color onError = Colors.white;

  static const Color info = Color(0xFF0A0A0A);              // = primary ink
  static const Color infoContainer = Color(0xFFF2F2F7);
  static const Color onInfo = Colors.white;

  // ── Status colours ───────────────────────────────────────────────────────
  // Each status keeps a deeply-muted semantic hue that reads as ink-tinted.
  static const Color statusAvailable = Color(0xFF14532D);   // forest green
  static const Color statusAvailableBg = Color(0xFFF0FDF4);
  static const Color statusAssigned = Color(0xFF0A0A0A);    // ink
  static const Color statusAssignedBg = Color(0xFFF7F7F8);
  static const Color statusMaintenance = Color(0xFF78350F); // dark amber
  static const Color statusMaintenanceBg = Color(0xFFFFFBEB);
  static const Color statusRetired = Color(0xFFA3A3A3);     // mid-gray
  static const Color statusRetiredBg = Color(0xFFF7F7F7);
  static const Color statusPending = Color(0xFF404040);     // graphite
  static const Color statusPendingBg = Color(0xFFEFEFEF);

  // ── Light neutrals (grouped / iOS-style) ─────────────────────────────────
  // Page is a soft gray so pure-white cards read clearly. All-white page +
  // white cards made surfaces disappear.
  static const Color lightBg = Color(0xFFF2F2F7);            // grouped table bg
  static const Color lightSurface = Color(0xFFFFFFFF);       // cards — white
  static const Color lightSurfaceVariant = Color(0xFFF7F7F8); // inputs
  static const Color lightSurfaceDim = Color(0xFFE8E8ED);     // snackbars / chips
  static const Color lightBorder = Color(0xFFDCDCE0);        // card hairline
  static const Color lightBorderStrong = Color(0xFFC7C7CC); // dividers
  // Softer label ink (Apple system label) — less “heavy black” on white.
  static const Color lightText = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightTextTertiary = Color(0xFFAEAEB2);
  static const Color lightTextQuaternary = Color(0xFFC7C7CC);

  // ── Dark neutrals ────────────────────────────────────────────────────────
  // Layered blacks. Pure #000 only used for press; surfaces are slightly
  // lifted so cards have natural separation in dark mode.
  static const Color darkBg = Color(0xFF050505);            // near-black bg
  static const Color darkSurface = Color(0xFF0F0F0F);       // cards
  static const Color darkSurfaceVariant = Color(0xFF151515);
  static const Color darkCard = Color(0xFF141414);
  static const Color darkBorder = Color(0xFF262626);        // hairline
  static const Color darkBorderStrong = Color(0xFF404040);  // separator
  static const Color darkText = Color(0xFFF5F5F5);          // primary ink
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextTertiary = Color(0xFF737373);

  // ── Chart colours ────────────────────────────────────────────────────────
  // Pure grayscale ramp with ink-tinted semantic deeps for the few cases
  // where data needs categorical distinction.
  static const List<Color> chartColors = [
    Color(0xFF0A0A0A), // ink
    Color(0xFF404040), // graphite
    Color(0xFF737373), // mid-gray
    Color(0xFFA3A3A3), // light gray
    Color(0xFFD4D4D4), // very light
    Color(0xFF14532D), // muted forest (success)
    Color(0xFF78350F), // muted amber (warning)
    Color(0xFF991B1B), // muted crimson (alert)
    Color(0xFF1F1F1F),
    Color(0xFF8E8E8E),
  ];

  // ── Premium shadow tokens ────────────────────────────────────────────────
  // Multi-layer shadows give depth that pure-flat themes lack. Use these
  // in widgets directly (e.g. `BoxDecoration(boxShadow: AppTheme.shadowSm)`).
  // Visible on #F2F2F7 page + white cards (previous tokens were invisible).
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x08000000), blurRadius: 32, offset: Offset(0, 16)),
  ];

  static final ThemeData light = _buildLightTheme();
  static final ThemeData dark = _buildDarkTheme();

  // ── Text theme ───────────────────────────────────────────────────────────
  static TextTheme _textTheme({required Brightness brightness}) {
    final bool isDark = brightness == Brightness.dark;
    final Color bodyColor = isDark ? darkText : lightText;
    final Color secondaryColor =
        isDark ? darkTextSecondary : lightTextSecondary;

    // Premium B&W typography: dramatic weight contrast (W400 body / W800
    // display) with negative tracking on display sizes — that's what
    // separates editorial-grade type from default Material.
    return GoogleFonts.interTextTheme(TextTheme(
      displayLarge: TextStyle(
          fontSize: 56, fontWeight: FontWeight.w800, height: 1.05, color: bodyColor, letterSpacing: -1.6),
      displayMedium: TextStyle(
          fontSize: 44, fontWeight: FontWeight.w800, height: 1.1, color: bodyColor, letterSpacing: -1.2),
      displaySmall: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w700, height: 1.15, color: bodyColor, letterSpacing: -0.8),
      headlineLarge: TextStyle(
          fontSize: 30, fontWeight: FontWeight.w700, height: 1.2, color: bodyColor, letterSpacing: -0.6),
      headlineMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: bodyColor, letterSpacing: -0.4),
      headlineSmall: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: bodyColor, letterSpacing: -0.3),
      titleLarge: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, height: 1.35, color: bodyColor, letterSpacing: -0.2),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: bodyColor, letterSpacing: -0.1),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: bodyColor),
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: bodyColor),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: bodyColor),
      bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: secondaryColor),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, height: 1.2, color: bodyColor, letterSpacing: 0.1),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, height: 1.2, color: secondaryColor, letterSpacing: 0.2),
      // Small label is uppercase-friendly with strong tracking — used for
      // section eyebrows and meta labels. Looks editorial.
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: secondaryColor, letterSpacing: 0.5),
    ));
  }

  // ── Light colour scheme ──────────────────────────────────────────────────
  static ColorScheme _lightColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primaryDark,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: lightText,
      tertiary: Color(0xFF262626),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFEDEDED),
      onTertiaryContainer: Color(0xFF0A0A0A),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: Color(0xFF7F1D1D),
      surface: lightSurface,
      onSurface: lightText,
      surfaceContainerHighest: Color(0xFFF5F5F7),
      surfaceContainerHigh: Color(0xFFFAFAFA),
      surfaceContainer: lightSurface,
      onSurfaceVariant: lightTextSecondary,
      outline: lightBorder,
      outlineVariant: Color(0xFFE8E8ED),
      scrim: Color(0x80000000),
      shadow: Color(0x10000000),
      inverseSurface: lightText,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFFD4D4D4),
    );
  }

  // ── Light theme ──────────────────────────────────────────────────────────
  static ThemeData _buildLightTheme() {
    final cs = _lightColorScheme();
    final tt = _textTheme(brightness: Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      textTheme: tt,
      scaffoldBackgroundColor: lightBg,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,

      // Translucent-feel app bar — flat with a hairline separator on scroll
      // (matches iOS large-title patterns).
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightText,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: lightText,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: lightText, size: 22),
        actionsIconTheme:
            const IconThemeData(color: lightText, size: 22),
        toolbarHeight: 56,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: lightTextTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: primary);
          }
          return base.copyWith(color: lightTextTertiary);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // BottomAppBar (operator/finance use this with a centered FAB notch).
      // White surface with a hairline top separator — iOS tab bar feel.
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Color(0x10000000),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          // Soft drop shadow — gives black buttons a sense of weight on
          // white surfaces without looking Material-y or heavy.
          elevation: 1,
          shadowColor: const Color(0x40000000),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          // Hairline border — feels refined; harsh strokes feel "Bootstrap-y".
          side: const BorderSide(color: lightBorderStrong, width: 1),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: lightSurface,
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        // Subtly-filled background on light surface — gives form fields
        // visual weight without a heavy border.
        fillColor: lightSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // Subtle ink ring on focus — premium feel without harshness.
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: lightTextTertiary, fontSize: 14),
        helperStyle:
            GoogleFonts.inter(fontSize: 12, color: lightTextSecondary),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: error),
        prefixIconColor: lightTextSecondary,
        suffixIconColor: lightTextSecondary,
      ),

      // Apple-pill chip: high-radius, no border, soft fill.
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: lightSurfaceVariant,
        showCheckmark: false,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: lightTextSecondary,
        indicator: const BoxDecoration(
          border: Border(bottom: BorderSide(color: primary, width: 2.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
        dividerColor: lightBorder,
      ),

      // White card on grouped gray: subtle stroke helps low-contrast displays.
      cardTheme: CardThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: const Color(0x12000000),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDCDCE0), width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: lightTextSecondary,
        textColor: lightText,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // Light snack bar — avoids a big black bar that makes the app feel
      // “dark mode” on an otherwise white shell.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurfaceDim,
        contentTextStyle:
            GoogleFonts.inter(color: lightText, fontSize: 14, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorderStrong, width: 1),
        ),
        elevation: 1,
        width: 400,
      ),

      // iOS alert: tall corner radius, very soft shadow.
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        shadowColor: const Color(0x14000000),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: lightText,
            letterSpacing: -0.2),
        contentTextStyle: GoogleFonts.inter(
            fontSize: 14, color: lightTextSecondary, height: 1.5),
      ),

      // iOS-style sheet: rounded top corners, soft shadow, pure white.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: lightBorderStrong,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryContainer,
        circularTrackColor: primaryContainer,
      ),

      // The FAB is the most prominent ink element on the screen — give it
      // a confident drop shadow with warm-tinted opacity so it feels
      // premium rather than stuck-on-flat.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 4,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: const CircleBorder(),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: error,
        textColor: Colors.white,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : lightTextTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : lightBorderStrong),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: lightBorderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : lightTextTertiary),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: lightBorder,
        thumbColor: primary,
        overlayColor: Color(0x1A0A0A0A),
      ),

      focusColor: const Color(0x100A0A0A),
      hoverColor: const Color(0x080A0A0A),
      highlightColor: const Color(0x080A0A0A),
    );
  }

  // ── Dark colour scheme ───────────────────────────────────────────────────
  static ColorScheme _darkColorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      // Pure inverse of the light theme: ink stays the same vocabulary.
      primary: Color(0xFFF5F5F5),          // off-white
      onPrimary: Color(0xFF0A0A0A),
      primaryContainer: Color(0xFF1F1F1F),
      onPrimaryContainer: Color(0xFFF5F5F5),
      secondary: Color(0xFFA3A3A3),
      onSecondary: Color(0xFF0A0A0A),
      secondaryContainer: Color(0xFF141414),
      onSecondaryContainer: Color(0xFFD4D4D4),
      tertiary: Color(0xFFD4D4D4),
      onTertiary: Color(0xFF0A0A0A),
      tertiaryContainer: Color(0xFF262626),
      onTertiaryContainer: Color(0xFFF5F5F5),
      error: Color(0xFFFCA5A5),            // muted red, dimmed for dark
      onError: Color(0xFF7F1D1D),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: darkSurface,
      onSurface: darkText,
      surfaceContainerHighest: darkSurfaceVariant,
      surfaceContainerHigh: darkCard,
      surfaceContainer: darkSurface,
      onSurfaceVariant: darkTextSecondary,
      outline: darkBorder,
      outlineVariant: Color(0xFF262626),
      scrim: Color(0x80000000),
      shadow: Color(0x40000000),
      inverseSurface: darkText,
      onInverseSurface: darkBg,
      inversePrimary: Color(0xFF404040),
    );
  }

  // ── Dark theme ───────────────────────────────────────────────────────────
  static ThemeData _buildDarkTheme() {
    final cs = _darkColorScheme();
    final tt = _textTheme(brightness: Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      textTheme: tt,
      scaffoldBackgroundColor: darkBg,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: darkBorder,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkText,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        iconTheme: const IconThemeData(color: darkText, size: 22),
        actionsIconTheme:
            const IconThemeData(color: darkTextSecondary, size: 22),
        toolbarHeight: 60,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: darkBorder,
        indicatorColor: const Color(0xFF2E2E2E),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFF5F5F5), size: 22);
          }
          return const IconThemeData(color: darkTextTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base =
              GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: const Color(0xFFF5F5F5));
          }
          return base.copyWith(color: darkTextTertiary);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: const BorderSide(color: darkBorderStrong, width: 1.5),
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.transparent,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: darkCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFF5F5F5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFCA5A5), width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: darkTextTertiary, fontSize: 14),
        helperStyle:
            GoogleFonts.inter(fontSize: 12, color: darkTextSecondary),
        errorStyle: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFFFCA5A5)),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
      ),

      chipTheme: ChipThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedColor: const Color(0xFF2E2E2E),
        labelStyle:
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        side: const BorderSide(color: darkBorder, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: darkCard,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: darkTextSecondary,
        indicator: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.primary, width: 2.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
        dividerColor: darkBorder,
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: darkTextSecondary,
        textColor: darkText,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkText,
        contentTextStyle: GoogleFonts.inter(color: darkBg, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 16,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
        contentTextStyle: GoogleFonts.inter(
            fontSize: 14, color: darkTextSecondary, height: 1.6),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFF5F5F5),
        linearTrackColor: Color(0xFF2E2E2E),
        circularTrackColor: Color(0xFF2E2E2E),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: Color(0xFFFCA5A5),
        textColor: Color(0xFF7F1D1D),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? darkBg : darkTextTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? const Color(0xFFF5F5F5)
                : darkBorder),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? const Color(0xFFF5F5F5)
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(darkBg),
        side: const BorderSide(color: darkBorderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? const Color(0xFFF5F5F5)
                : darkTextTertiary),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFFF5F5F5),
        inactiveTrackColor: darkBorder,
        thumbColor: Color(0xFFF5F5F5),
        overlayColor: Color(0x1AF5F5F5),
      ),

      focusColor: Colors.white.withOpacity(0.08),
      hoverColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.05),
    );
  }

  // ── Status colour helpers ─────────────────────────────────────────────────
  static Color statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return statusAvailable;
      case 'assigned':
        return statusAssigned;
      case 'maintenance':
        return statusMaintenance;
      case 'retired':
        return statusRetired;
      case 'pending':
        return statusPending;
      default:
        return secondary;
    }
  }

  static Color statusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return statusAvailableBg;
      case 'assigned':
        return statusAssignedBg;
      case 'maintenance':
        return statusMaintenanceBg;
      case 'retired':
        return statusRetiredBg;
      case 'pending':
        return statusPendingBg;
      default:
        return lightSurfaceVariant;
    }
  }
}

// ── Status colour extension ──────────────────────────────────────────────────
extension StatusColors on BuildContext {
  Color getStatusColor(String? status) => AppTheme.statusColor(status);
  Color getStatusBgColor(String? status) => AppTheme.statusBgColor(status);
}
