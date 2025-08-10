import 'package:flutter/material.dart';

import '../utils/config.dart';
import '../logic/theme.dart';
import '../services/app_initialization_service.dart';
import 'main_screen.dart';
import 'splash_screen_wrapper.dart';

class ThemeAppWrapper extends StatefulWidget {
  const ThemeAppWrapper({super.key});

  @override
  State<ThemeAppWrapper> createState() => _ThemeAppWrapperState();
}

class _ThemeAppWrapperState extends State<ThemeAppWrapper> {
  bool _initialized = false;
  late ThemeMode _themeMode = ThemeMode.system;
  final AppInitializationService _initService = AppInitializationService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;

    // Load theme mode
    final config = await ConfigManager.loadConfig();
    if (mounted) {
      setState(() {
        _themeMode = ThemeManager.getThemeMode(
          config['themeMode'] ?? ThemeMode.system.index,
        );
      });
    }

    // Initialize app dependencies
    final success = await _initService.initializeApp(context, () {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });

    if (success && mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    if (!mounted) return;
    setState(() => _themeMode = mode);
    final config = await ConfigManager.loadConfig();
    config['themeMode'] = ThemeManager.getThemeIndex(mode);
    await ConfigManager.saveConfig(config);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeManager.getLightTheme(),
      darkTheme: ThemeManager.getDarkTheme(),
      themeMode: _themeMode,
      home: _initialized
          ? MainScreen(updateThemeMode: _updateThemeMode, themeMode: _themeMode)
          : SplashScreenWrapper(
              updateThemeMode: _updateThemeMode,
              themeMode: _themeMode,
            ),
    );
  }
}
