import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0066FF);
  static const onPrimary = Colors.white;

  static const surface = Color(0xFFF8FAFF);
  static const onSurface = Color(0xFF0E1824);

  static const surfaceMuted = Color(0xFFF2F4F7);
  static const outline = Color(0xFFE5E7EB);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
}

class AppRadii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

class AppSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      useMaterial3: true,
    );

    var cardTheme = CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.outline),
      ),
    );
    var cardTheme2 = cardTheme;
    var cardTheme22 = cardTheme2;
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineSmall: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
        titleMedium:
            GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(.65)),
      ),
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: widget(child: cardTheme22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outline),
    );
  }

  static ThemeData? get dark => null;

  // ignore: strict_top_level_inference
  static widget({required CardTheme child}) {}
}
