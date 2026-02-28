import 'package:flutter/material.dart';

const Color _primary = Color(0xFF7C4DFF); // medium purple
const Color _secondary = Color(0xFFFF8A50); // medium orange
const Color _background = Color(0xFF0B0B0D);
const Color _surface = Color(0xFF121214);
const Color _onBackground = Color(0xFFE6E6E9);

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.light,
    secondary: _secondary,
  ),
  useMaterial3: true,
);

final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: _primary,
    secondary: _secondary,
    background: _background,
    surface: _surface,
    onBackground: _onBackground,
    onSurface: _onBackground,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
  ),
  scaffoldBackgroundColor: _background,
  appBarTheme: const AppBarTheme(
    backgroundColor: _surface,
    foregroundColor: _onBackground,
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: _surface,
    selectedItemColor: _primary,
    unselectedItemColor: _onBackground.withOpacity(0.7),
  ),
  useMaterial3: true,
);

// Default theme reference (keeps backward compatibility)
final ThemeData appTheme = darkTheme;
