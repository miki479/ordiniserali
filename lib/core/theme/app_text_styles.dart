import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font families used across the app, mirroring the original CSS:
/// Fraunces for display/headings, Inter for body copy, IBM Plex Mono
/// for the "receipt" / label typography.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle display({
    required Color color,
    double fontSize = 34,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.fraunces(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: FontStyle.italic,
      height: 1.1,
    );
  }

  static TextStyle mono({
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.2,
  }) {
    return GoogleFonts.ibmPlexMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme(Color textColor) {
    return GoogleFonts.interTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
  }
}
