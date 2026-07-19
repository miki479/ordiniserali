import 'package:flutter/material.dart';

/// Brand palette from the original Vico Meal web app, exposed as a
/// [ThemeExtension] so every widget can read `Theme.of(context).extension<AppColors>()`
/// without threading colors through constructors.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.inkSoft,
    required this.wine,
    required this.wineDeep,
    required this.tomato,
    required this.tomatoDeep,
    required this.olive,
    required this.oliveDeep,
    required this.mustard,
    required this.line,
    required this.card,
  });

  final Color paper;
  final Color paperDeep;
  final Color ink;
  final Color inkSoft;
  final Color wine;
  final Color wineDeep;
  final Color tomato;
  final Color tomatoDeep;
  final Color olive;
  final Color oliveDeep;
  final Color mustard;
  final Color line;
  final Color card;

  static const light = AppColors(
    paper: Color(0xFFFBF1E4),
    paperDeep: Color(0xFFF3E4CD),
    ink: Color(0xFF2B211B),
    inkSoft: Color(0xFF6B5F53),
    wine: Color(0xFF6B2737),
    wineDeep: Color(0xFF54101F),
    tomato: Color(0xFFC1440E),
    tomatoDeep: Color(0xFF9C3509),
    olive: Color(0xFF6B7A3A),
    oliveDeep: Color(0xFF525D2B),
    mustard: Color(0xFFE3A72B),
    line: Color(0x242B211B),
    card: Colors.white,
  );

  static const dark = AppColors(
    paper: Color(0xFF1C1712),
    paperDeep: Color(0xFF241C15),
    ink: Color(0xFFF2E6D8),
    inkSoft: Color(0xFFB7A896),
    wine: Color(0xFF9C5468),
    wineDeep: Color(0xFF7A3A4C),
    tomato: Color(0xFFE0713F),
    tomatoDeep: Color(0xFFC1440E),
    olive: Color(0xFF95A75A),
    oliveDeep: Color(0xFF788C3F),
    mustard: Color(0xFFE3B23F),
    line: Color(0x33F2E6D8),
    card: Color(0xFF29221B),
  );

  @override
  AppColors copyWith({
    Color? paper,
    Color? paperDeep,
    Color? ink,
    Color? inkSoft,
    Color? wine,
    Color? wineDeep,
    Color? tomato,
    Color? tomatoDeep,
    Color? olive,
    Color? oliveDeep,
    Color? mustard,
    Color? line,
    Color? card,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      paperDeep: paperDeep ?? this.paperDeep,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      wine: wine ?? this.wine,
      wineDeep: wineDeep ?? this.wineDeep,
      tomato: tomato ?? this.tomato,
      tomatoDeep: tomatoDeep ?? this.tomatoDeep,
      olive: olive ?? this.olive,
      oliveDeep: oliveDeep ?? this.oliveDeep,
      mustard: mustard ?? this.mustard,
      line: line ?? this.line,
      card: card ?? this.card,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      paperDeep: Color.lerp(paperDeep, other.paperDeep, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      wine: Color.lerp(wine, other.wine, t)!,
      wineDeep: Color.lerp(wineDeep, other.wineDeep, t)!,
      tomato: Color.lerp(tomato, other.tomato, t)!,
      tomatoDeep: Color.lerp(tomatoDeep, other.tomatoDeep, t)!,
      olive: Color.lerp(olive, other.olive, t)!,
      oliveDeep: Color.lerp(oliveDeep, other.oliveDeep, t)!,
      mustard: Color.lerp(mustard, other.mustard, t)!,
      line: Color.lerp(line, other.line, t)!,
      card: Color.lerp(card, other.card, t)!,
    );
  }
}

/// Shorthand accessor: `context.colors.tomato`.
extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
