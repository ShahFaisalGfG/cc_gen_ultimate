import 'package:flutter/material.dart';

import '../logic/preferences.dart';
import '../ui/about_section.dart';
import '../ui/bottom_bar.dart';
import '../ui/widgets/logs_panel.dart';
import '../ui/generate_cc_tab.dart';
import '../ui/translate_cc_tab.dart';
import '../ui/models_tab.dart';

class MainScreen extends StatefulWidget {
  final void Function(ThemeMode) updateThemeMode;
  final ThemeMode themeMode;
  const MainScreen({
    super.key,
    required this.updateThemeMode,
    required this.themeMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;
  late ThemeMode _themeMode;
  String _selectedModel = 'tiny';
  String _selectedLanguage = 'English';
  String _translateFrom = 'English';
  String _translateTo = 'None';
  String _selectedFormat = '.srt';
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await Preferences.loadPreferences();
    if (!mounted) return;
    setState(() {
      _selectedModel = prefs['selectedModel'] ?? 'tiny';
      _selectedLanguage = prefs['selectedLanguage'] ?? 'English';
      _translateFrom = prefs['translateFrom'] ?? 'English';
      _translateTo = prefs['translateTo'] ?? 'None';
      _selectedFormat = prefs['selectedFormat'] ?? '.srt';
      _themeMode =
          ThemeMode.values[int.tryParse(prefs['themeMode'] ?? '2') ?? 2];
      widget.updateThemeMode(_themeMode);
    });
  }

  Future<void> _saveConfig() async {
    await Preferences.savePreferences({
      'selectedModel': _selectedModel,
      'selectedLanguage': _selectedLanguage,
      'translateFrom': _translateFrom,
      'translateTo': _translateTo,
      'selectedFormat': _selectedFormat,
      'themeMode': _themeMode.index.toString(),
    });
    widget.updateThemeMode(_themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon.png', width: 32, height: 32),
            const SizedBox(width: 12),
            const Text('CC Gen Ultimate'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AboutSection(),
              );
            },
          ),
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.color_lens_outlined),
            tooltip: 'Theme',
            onSelected: (mode) {
              setState(() => _themeMode = mode);
              _saveConfig();
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: ThemeMode.system,
                checked: _themeMode == ThemeMode.system,
                child: const Text('System'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.light,
                checked: _themeMode == ThemeMode.light,
                child: const Text('Light'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.dark,
                checked: _themeMode == ThemeMode.dark,
                child: const Text('Dark'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showLogs = !_showLogs;
              });
            },
            tooltip: _showLogs ? 'Hide Logs' : 'Show Logs',
          ),
        ],
      ),
      body: BottomBar(
        selectedTab: _selectedTab,
        tabBarContent: Expanded(child: _buildTabContent()),
        logsPanel: LogsPanel(showLogs: _showLogs),
        onTabChanged: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return GenerateCCTab();
      case 1:
        return TranslateCCTab();
      case 2:
        return const ModelsAndLanguagesTab();
      default:
        return const SizedBox();
    }
  }
}
