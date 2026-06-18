import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Apple Human Interface Guidelines — Dark Theme
/// SF Pro estetiğini Inter fontuyla yakalar.
/// Apple'ın tipografi hiyerarşisini (Large Title, Title1, Headline, Body vb.) takip eder.
class AppTheme {
  AppTheme._();

  // ── Apple iOS Radius Standartları ─────────────────────────────
  static const double radiusS  = 10.0;
  static const double radiusM  = 12.0;
  static const double radiusL  = 16.0;
  static const double radiusXL = 20.0;

  /// Inter TextStyle üretici
  static TextStyle _inter({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.label,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ── Renk Şeması ──────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF003A7A),
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.systemOrange,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF3E2800),
        onSecondaryContainer: Color(0xFFFFB74D),
        tertiary: AppColors.systemTeal,
        surface: AppColors.surface,
        onSurface: AppColors.label,
        surfaceContainerHighest: AppColors.surfaceHighlight,
        outline: AppColors.separator,
        outlineVariant: AppColors.opaqueSeparator,
        error: AppColors.error,
        onError: Colors.white,
      ),

      // ── Scaffold ─────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar — iOS Large Title Tarzı ───────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary, size: 22),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
      ),

      // ── Metin Stilleri — Apple Tipografi Hiyerarşisi ─────────
      textTheme: TextTheme(
        // Large Title (34pt, Bold)
        displayLarge: _inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
        ),
        // Title 1 (28pt, Bold)
        displayMedium: _inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.36,
        ),
        // Title 2 (22pt, Bold)
        displaySmall: _inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
        // Title 3 (20pt, SemiBold)
        headlineLarge: _inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.38,
        ),
        // Headline (17pt, SemiBold)
        headlineMedium: _inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        // Subheadline (15pt, Regular)
        headlineSmall: _inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryLabel,
          letterSpacing: -0.2,
        ),
        // Body (17pt, Regular)
        titleLarge: _inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        // Callout (16pt, Regular)
        titleMedium: _inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        // Footnote (13pt, Regular)
        titleSmall: _inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        // Body (17pt)
        bodyLarge: _inter(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
          height: 1.3,
        ),
        // Callout (16pt)
        bodyMedium: _inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        // Caption 1 (12pt)
        bodySmall: _inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryLabel,
          letterSpacing: -0.1,
        ),
        // Footnote (13pt, SemiBold)
        labelLarge: _inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        // Caption 2 (11pt)
        labelMedium: _inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryLabel,
        ),
        // Caption 2 Muted
        labelSmall: _inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.tertiaryLabel,
        ),
      ),

      // ── Kartlar — iOS Grouped Inset ──────────────────────────
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Elevated Button — iOS Filled Button ──────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: _inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),

      // ── Outlined Button — iOS Gray Button ────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.separator, width: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: _inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button — iOS Plain Button ───────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _inter(
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // ── Input — iOS Search Bar / Text Field ──────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tertiaryBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: _inter(
          fontSize: 17,
          color: AppColors.tertiaryLabel,
          letterSpacing: -0.4,
        ),
        labelStyle: _inter(
          fontSize: 17,
          color: AppColors.secondaryLabel,
        ),
      ),

      // ── Chip — iOS Tag Style ─────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.tertiaryBackground,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: _inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryLabel,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider — iOS Separator ──────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.separator,
        thickness: 0.5,
        space: 0.5,
      ),

      // ── Bottom Navigation — iOS Tab Bar ──────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return _inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.tertiaryLabel,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.tertiaryLabel, size: 24);
        }),
      ),

      // ── SnackBar ─────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: _inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.label,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Dialog — iOS Alert ───────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // iOS alert radius
        ),
        elevation: 0,
      ),

      // ── Bottom Sheet — iOS Modal ─────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusS),
          ),
        ),
        dragHandleColor: AppColors.surfaceHighlight,
        dragHandleSize: Size(36, 5),
      ),

      // ── ListTile ─────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        iconColor: AppColors.secondaryLabel,
        textColor: AppColors.label,
      ),

      // ── Splash & Highlights ──────────────────────────────────
      splashColor: AppColors.fill,
      highlightColor: AppColors.secondaryFill,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
