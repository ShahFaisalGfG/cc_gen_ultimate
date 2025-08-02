import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool reversed;

  const GradientBackground({
    super.key,
    required this.child,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeManager.gradientColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: reversed ? colors.reversed.toList() : colors,
        ),
      ),
      child: child,
    );
  }
}

class ThemeManager {
  static ThemeMode getThemeMode(int index) {
    return ThemeMode.values[index];
  }

  static int getThemeIndex(ThemeMode mode) {
    return mode.index;
  }

  static const gradientColors = [
    Color(0xFF7F53FF),  // Purple
    Color(0xFF647DEE),  // Blue
  ];

  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: gradientColors[0],
      colorScheme: ColorScheme.light(
        primary: gradientColors[0],
        secondary: gradientColors[1],
        surface: Colors.white,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF7F53FF),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF647DEE),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      dividerColor: const Color(0xFF7F53FF),
      iconTheme: const IconThemeData(color: Color(0xFF647DEE)),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: gradientColors[1],
      colorScheme: ColorScheme.dark(
        primary: gradientColors[1],
        secondary: gradientColors[0],
        surface: const Color(0xFF23272F),
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF181A20),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF23272F),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7F53FF),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      dividerColor: const Color(0xFF647DEE),
      iconTheme: const IconThemeData(color: Color(0xFF7F53FF)),
    );
  }
}
