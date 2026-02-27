import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  static TextTheme textTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );
}
