import 'package:flutter/material.dart';

import '../../services/core/app_initialization_service.dart';
import '../screens/splash_screen.dart';
import '../screens/main_screen.dart';

class SplashScreenWrapper extends StatefulWidget {
  final void Function(ThemeMode) updateThemeMode;
  final ThemeMode themeMode;
  const SplashScreenWrapper({
    super.key,
    required this.updateThemeMode,
    required this.themeMode,
  });

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _showSplash = true;
  final AppInitializationService _initService = AppInitializationService();

  @override
  void initState() {
    super.initState();
    _checkDependencies();
  }

  Future<void> _checkDependencies() async {
    await _initService.checkDependenciesForSplash(context, () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? const SplashScreen()
        : MainScreen(
            updateThemeMode: widget.updateThemeMode,
            themeMode: widget.themeMode,
          );
  }
}
