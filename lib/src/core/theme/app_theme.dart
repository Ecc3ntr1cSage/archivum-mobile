import 'package:flutter/material.dart';

class ArchivumTheme extends ThemeExtension<ArchivumTheme> {
  const ArchivumTheme({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;

  @override
  ArchivumTheme copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
    Color? sidebar,
    Color? sidebarForeground,
    Color? sidebarAccent,
    Color? sidebarAccentForeground,
  }) {
    return ArchivumTheme(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
      sidebar: sidebar ?? this.sidebar,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      sidebarAccentForeground:
          sidebarAccentForeground ?? this.sidebarAccentForeground,
    );
  }

  @override
  ArchivumTheme lerp(ThemeExtension<ArchivumTheme>? other, double t) {
    if (other is! ArchivumTheme) return this;

    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;

    return ArchivumTheme(
      background: lerpColor(background, other.background),
      foreground: lerpColor(foreground, other.foreground),
      card: lerpColor(card, other.card),
      cardForeground: lerpColor(cardForeground, other.cardForeground),
      popover: lerpColor(popover, other.popover),
      popoverForeground: lerpColor(popoverForeground, other.popoverForeground),
      primary: lerpColor(primary, other.primary),
      primaryForeground: lerpColor(primaryForeground, other.primaryForeground),
      secondary: lerpColor(secondary, other.secondary),
      secondaryForeground: lerpColor(
        secondaryForeground,
        other.secondaryForeground,
      ),
      muted: lerpColor(muted, other.muted),
      mutedForeground: lerpColor(mutedForeground, other.mutedForeground),
      accent: lerpColor(accent, other.accent),
      accentForeground: lerpColor(accentForeground, other.accentForeground),
      destructive: lerpColor(destructive, other.destructive),
      destructiveForeground: lerpColor(
        destructiveForeground,
        other.destructiveForeground,
      ),
      border: lerpColor(border, other.border),
      input: lerpColor(input, other.input),
      ring: lerpColor(ring, other.ring),
      chart1: lerpColor(chart1, other.chart1),
      chart2: lerpColor(chart2, other.chart2),
      chart3: lerpColor(chart3, other.chart3),
      chart4: lerpColor(chart4, other.chart4),
      chart5: lerpColor(chart5, other.chart5),
      sidebar: lerpColor(sidebar, other.sidebar),
      sidebarForeground: lerpColor(sidebarForeground, other.sidebarForeground),
      sidebarAccent: lerpColor(sidebarAccent, other.sidebarAccent),
      sidebarAccentForeground: lerpColor(
        sidebarAccentForeground,
        other.sidebarAccentForeground,
      ),
    );
  }
}

extension ArchivumThemeContext on BuildContext {
  ArchivumTheme get archivumTheme => Theme.of(this).extension<ArchivumTheme>()!;
}

const _lightTokens = ArchivumTheme(
  background: Color(0xFFFFFFFF),
  foreground: Color(0xFF111827),
  card: Color(0xFFFFFFFF),
  cardForeground: Color(0xFF111827),
  popover: Color(0xFFFFFFFF),
  popoverForeground: Color(0xFF111827),
  primary: Color(0xFFD87943),
  primaryForeground: Color(0xFFFFFFFF),
  secondary: Color(0xFF527575),
  secondaryForeground: Color(0xFFFFFFFF),
  muted: Color(0xFFF3F4F6),
  mutedForeground: Color(0xFF6B7280),
  accent: Color(0xFFEEEEEE),
  accentForeground: Color(0xFF111827),
  destructive: Color(0xFFEF4444),
  destructiveForeground: Color(0xFFFAFAFA),
  border: Color(0xFFE5E7EB),
  input: Color(0xFFE5E7EB),
  ring: Color(0xFFD87943),
  chart1: Color(0xFF5F8787),
  chart2: Color(0xFFE78A53),
  chart3: Color(0xFFFBCB97),
  chart4: Color(0xFF888888),
  chart5: Color(0xFF999999),
  sidebar: Color(0xFFF3F4F6),
  sidebarForeground: Color(0xFF111827),
  sidebarAccent: Color(0xFFFFFFFF),
  sidebarAccentForeground: Color(0xFF111827),
);

const _darkTokens = ArchivumTheme(
  background: Color(0xFF121113),
  foreground: Color(0xFFC1C1C1),
  card: Color(0xFF121212),
  cardForeground: Color(0xFFC1C1C1),
  popover: Color(0xFF121113),
  popoverForeground: Color(0xFFC1C1C1),
  primary: Color(0xFFE78A53),
  primaryForeground: Color(0xFF121113),
  secondary: Color(0xFF5F8787),
  secondaryForeground: Color(0xFF121113),
  muted: Color(0xFF222222),
  mutedForeground: Color(0xFF888888),
  accent: Color(0xFF333333),
  accentForeground: Color(0xFFC1C1C1),
  destructive: Color(0xFF5F8787),
  destructiveForeground: Color(0xFF121113),
  border: Color(0xFF222222),
  input: Color(0xFF222222),
  ring: Color(0xFFE78A53),
  chart1: Color(0xFF5F8787),
  chart2: Color(0xFFE78A53),
  chart3: Color(0xFFFBCB97),
  chart4: Color(0xFF888888),
  chart5: Color(0xFF999999),
  sidebar: Color(0xFF121212),
  sidebarForeground: Color(0xFFC1C1C1),
  sidebarAccent: Color(0xFF333333),
  sidebarAccentForeground: Color(0xFFC1C1C1),
);

ThemeData _buildDarkMatterTheme({
  required Brightness brightness,
  required ArchivumTheme tokens,
}) {
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: tokens.primary,
    onPrimary: tokens.primaryForeground,
    secondary: tokens.secondary,
    onSecondary: tokens.secondaryForeground,
    error: tokens.destructive,
    onError: tokens.destructiveForeground,
    surface: tokens.card,
    onSurface: tokens.cardForeground,
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.background,
    canvasColor: tokens.background,
    cardColor: tokens.card,
    dividerColor: tokens.border,
    useMaterial3: true,
    extensions: <ThemeExtension<dynamic>>[tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.background,
      foregroundColor: tokens.foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.popover,
      modalBackgroundColor: tokens.popover,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.input.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.ring, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.primaryForeground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: tokens.primary),
    ),
    iconTheme: IconThemeData(color: tokens.foreground),
    textTheme: Typography.material2021().black.apply(
      bodyColor: tokens.foreground,
      displayColor: tokens.foreground,
    ),
  );
}

final ThemeData lightTheme = _buildDarkMatterTheme(
  brightness: Brightness.light,
  tokens: _lightTokens,
);

final ThemeData darkTheme = _buildDarkMatterTheme(
  brightness: Brightness.dark,
  tokens: _darkTokens,
);

final ThemeData appTheme = darkTheme;
