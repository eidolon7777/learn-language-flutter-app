import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get lightTextTheme => GoogleFonts.lexendTextTheme().copyWith(
    // H1: 36px, Bold (700)
    headlineLarge: GoogleFonts.lexend(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: AppColors.lightText,
    ),
    // H2: 24px, Semibold (600)
    titleLarge: GoogleFonts.lexend(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
    ),
    // Body: 16px, Regular (400)
    bodyMedium: GoogleFonts.lexend(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.lightBodyText,
    ),
    // Caption: 14px, Light (300)
    bodySmall: GoogleFonts.lexend(
      fontSize: 14,
      fontWeight: FontWeight.w300,
      color: AppColors.lightCaptionText,
    ),
  );

  static TextTheme get darkTextTheme => GoogleFonts.lexendTextTheme().copyWith(
    // H1: 36px, Bold (700)
    headlineLarge: GoogleFonts.lexend(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: AppColors.darkText,
    ),
    // H2: 24px, Semibold (600)
    titleLarge: GoogleFonts.lexend(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
    ),
    // Body: 16px, Regular (400)
    bodyMedium: GoogleFonts.lexend(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.darkBodyText,
    ),
    // Caption: 14px, Light (300)
    bodySmall: GoogleFonts.lexend(
      fontSize: 14,
      fontWeight: FontWeight.w300,
      color: AppColors.darkCaptionText,
    ),
  );
}
