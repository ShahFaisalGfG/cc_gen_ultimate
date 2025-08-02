import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers and State
import 'controllers/whisper_controller.dart';
import 'state/translation_state.dart';
import 'state/logs_state.dart';

// Logic
import 'utils/config.dart';
import 'logic/theme.dart';
import 'logic/preferences.dart';
import 'logic/logs.dart';

// Services
import 'services/configuration_service.dart';
import 'services/dependency_manager.dart';

// UI Components
import 'ui/splash_screen.dart';
import 'ui/about_section.dart';
import 'ui/bottom_bar.dart';
import 'ui/widgets/logs_panel.dart';
import 'ui/generate_cc_tab.dart';
import 'ui/translate_cc_tab.dart';
import 'ui/models_tab.dart';
import 'ui/widgets/dependency_check_dialog.dart';
import 'ui/widgets/dependency_install_progress.dart';

// Global keys for state management
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> requestAndroidPermissions() async {
  if (Platform.isAndroid) {
    // TODO: Implement Android permissions request
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestAndroidPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WhisperController()),
        ChangeNotifierProvider(create: (_) => TranslationState()),
      ],
      child: ThemeAppWrapper(),
    ),
  );
}

class ThemeAppWrapper extends StatefulWidget {
  const ThemeAppWrapper({super.key});

  @override
  State<ThemeAppWrapper> createState() => _ThemeAppWrapperState();
}

class _ThemeAppWrapperState extends State<ThemeAppWrapper> {
  bool _initialized = false;
  late ThemeMode _themeMode = ThemeMode.system;
  final ConfigurationService _configService = ConfigurationService();
  final LogsState _logsState = LogsState();

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
        _themeMode = ThemeManager.getThemeMode(config['themeMode'] ?? ThemeMode.system.index);
      });
    }

    // Check dependencies
    try {
      final status = await _configService.checkDependencies();
      final allDependenciesInstalled = status.values.every((installed) => installed);

      for (var entry in status.entries) {
        _logsState.addLog(
          '${entry.key}: ${entry.value ? "Installed ✓" : "Not installed ✗"}',
          level: entry.value ? LogLevel.success : LogLevel.warning,
        );
      }

      if (!allDependenciesInstalled && mounted) {
        _logsState.addLog('Missing dependencies detected. Installation required.', level: LogLevel.warning);
        final completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => DependencyCheckDialog(
              initialStatus: status,
              logsState: _logsState,
              onRetryPressed: () {
                _logsState.addLog('Retrying dependency check...');
                Navigator.pop(dialogContext);
                _initializeApp();
                completer.complete();
              },
              onClosePressed: () {
                _logsState.addLog('Dependency check skipped by user.', level: LogLevel.warning);
                Navigator.pop(dialogContext);
                completer.complete();
              },
              showInstallButton: status['python']! && !status.values.every((v) => v),
              onInstallDependency: (dependency) async {
                try {
                  final dependencyManager = DependencyManager();
                  bool isRetrying = true;
                  bool shouldContinue = true;

                  while (isRetrying && shouldContinue && mounted) {
                    final result = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => DependencyInstallProgress(
                        currentStep: dependency,
                        totalSteps: 1,
                        currentStepIndex: 1,
                        details: 'Installing $dependency...',
                        showInstallButton: false,
                        showNextButton: false,
                        logsStream: dependencyManager.installDependency(dependency).map((step) {
                          _logsState.addLog(
                            step.logs ?? step.details,
                            level: step.error != null
                                ? LogLevel.error
                                : step.success
                                    ? LogLevel.success
                                    : LogLevel.info,
                          );
                          return step.logs ?? step.details;
                        }),
                        logsState: _logsState,
                        onCancelPressed: () {
                          _logsState.addLog('Installation cancelled by user.', level: LogLevel.warning);
                          Navigator.pop(context, 'cancel');
                        },
                        onRetryPressed: () {
                          _logsState.addLog('Retrying installation of $dependency...', level: LogLevel.info);
                          Navigator.pop(context, 'retry');
                        },
                      ),
                    );

                    if (result == 'cancel') {
                      shouldContinue = false;
                      break;
                    } else if (result == 'retry') {
                      isRetrying = true;
                      continue;
                    } else {
                      isRetrying = false;
                    }
                  }

                  if (mounted && shouldContinue) {
                    _initializeApp();
                  }
                } catch (e) {
                  _logsState.addLog('Failed to install $dependency: $e', level: LogLevel.error);
                  if (mounted) {
                    scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Failed to install $dependency: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },

            ),
          );
        });

        await completer.future;
        return;
      } else {
        _logsState.addLog('All dependencies are installed.', level: LogLevel.success);
      }
    } catch (e) {
      _logsState.addLog('Error checking dependencies: $e', level: LogLevel.error);
      if (mounted) {
        final completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => DependencyCheckDialog(
              initialStatus: {},
              logsState: _logsState,
              onRetryPressed: () {
                _logsState.addLog('Retrying after error...');
                Navigator.pop(dialogContext);
                _initializeApp();
                completer.complete();
              },
              onClosePressed: () {
                _logsState.addLog('Check aborted after error.', level: LogLevel.error);
                Navigator.pop(dialogContext);
                completer.complete();
              },
              showInstallButton: false,
            ),
          );
        });
        await completer.future;
        return;
      }
    }

    if (mounted) {
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
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      theme: ThemeManager.getLightTheme(),
      darkTheme: ThemeManager.getDarkTheme(),
      themeMode: _themeMode,
      home: _initialized
          ? MainScreen(updateThemeMode: _updateThemeMode, themeMode: _themeMode)
          : SplashScreenWrapper(updateThemeMode: _updateThemeMode, themeMode: _themeMode),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  final void Function(ThemeMode) updateThemeMode;
  final ThemeMode themeMode;
  const SplashScreenWrapper({super.key, required this.updateThemeMode, required this.themeMode});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _showSplash = true;
  final ConfigurationService _configService = ConfigurationService();
  final LogsState _logsState = LogsState();

  @override
  void initState() {
    super.initState();
    _checkDependencies();
  }

  Future<void> _checkDependencies() async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      setState(() => _showSplash = false);
      return;
    }

    _logsState.addLog('Starting dependency check...');
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final status = await _configService.checkDependencies();
      final allDependenciesInstalled = status.values.every((installed) => installed);

      for (var entry in status.entries) {
        _logsState.addLog(
          '${entry.key}: ${entry.value ? "Installed ✓" : "Not installed ✗"}',
          level: entry.value ? LogLevel.success : LogLevel.warning,
        );
      }

      if (!allDependenciesInstalled && mounted) {
        _logsState.addLog('Missing dependencies detected. Installation required.', level: LogLevel.warning);
        final completer = Completer<void>();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DependencyCheckDialog(
            initialStatus: status,
            logsState: _logsState,
            onRetryPressed: () {
              _logsState.addLog('Retrying dependency check...');
              Navigator.pop(dialogContext);
              _checkDependencies();
              completer.complete();
            },
            onClosePressed: () {
              _logsState.addLog('Dependency check skipped by user.', level: LogLevel.warning);
              Navigator.pop(dialogContext);
              setState(() => _showSplash = false);
              completer.complete();
            },
            showInstallButton: status['python']! && !status.values.every((v) => v),
            onInstallDependency: (dependency) async {
              try {
                final dependencyManager = DependencyManager();
                bool isRetrying = true;
                bool shouldContinue = true;

                while (isRetrying && shouldContinue && mounted) {
                  final result = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => DependencyInstallProgress(
                      currentStep: dependency,
                      totalSteps: status.length,
                      currentStepIndex: status.keys.toList().indexOf(dependency) + 1,
                      details: 'Installing $dependency...',
                      showInstallButton: false,
                      showNextButton: true,
                      logsStream: dependencyManager.installDependency(dependency).map((step) {
                        _logsState.addLog(
                          step.logs ?? step.details,
                          level: step.error != null
                              ? LogLevel.error
                              : step.success
                                  ? LogLevel.success
                                  : LogLevel.info,
                        );
                        return step.logs ?? step.details;
                      }),
                      logsState: _logsState,
                      onCancelPressed: () {
                        _logsState.addLog('Installation cancelled by user.', level: LogLevel.warning);
                        Navigator.pop(context, 'cancel');
                      },
                      onRetryPressed: () {
                        _logsState.addLog('Retrying installation of $dependency...', level: LogLevel.info);
                        Navigator.pop(context, 'retry');
                      },
                      onInstallDependency: (nextDep) async {
                        Navigator.pop(context, 'next');
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => DependencyInstallProgress(
                            currentStep: nextDep,
                            totalSteps: status.length,
                            currentStepIndex: status.keys.toList().indexOf(nextDep) + 1,
                            details: 'Installing $nextDep...',
                            logsState: _logsState,
                            logsStream: dependencyManager.installDependency(nextDep).map((step) => step.logs ?? step.details),
                            onInstallDependency: (nextDep) async {
                              Navigator.pop(context);
                              await _checkDependencies();
                            },
                            onFinish: () {
                              _logsState.addLog('All dependencies installed successfully.', level: LogLevel.success);
                              _checkDependencies();
                            },
                          ),
                        );
                      },
                      onFinish: () {
                        _logsState.addLog('All dependencies installed successfully.', level: LogLevel.success);
                        _checkDependencies();
                      },
                    ),
                  );

                  if (result == 'cancel') {
                    shouldContinue = false;
                    break;
                  } else if (result == 'retry') {
                    isRetrying = true;
                    continue;
                  } else {
                    isRetrying = false;
                  }
                }

                if (mounted && shouldContinue) {
                  _checkDependencies();
                }
              } catch (e) {
                _logsState.addLog('Failed to install $dependency: $e', level: LogLevel.error);
                if (mounted) {
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text('Failed to install $dependency: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        );
        completer.complete();
      } else {
        _logsState.addLog('All dependencies are installed.', level: LogLevel.success);
        setState(() => _showSplash = false);
      }
    } catch (e) {
      _logsState.addLog('Error checking dependencies: $e', level: LogLevel.error);
      if (!mounted) return;

      final completer = Completer<void>();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DependencyCheckDialog(
          initialStatus: {},
          logsState: _logsState,
          onRetryPressed: () {
            _logsState.addLog('Retrying after error...');
            Navigator.pop(dialogContext);
            _checkDependencies();
            completer.complete();
          },
          onClosePressed: () {
            _logsState.addLog('Check aborted after error.', level: LogLevel.error);
            Navigator.pop(dialogContext);
            setState(() => _showSplash = false);
            completer.complete();
          },
          showInstallButton: false,
        ),
      );
      completer.complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? const SplashScreen()
        : MainScreen(updateThemeMode: widget.updateThemeMode, themeMode: widget.themeMode);
  }
}

class MainScreen extends StatefulWidget {
  final void Function(ThemeMode) updateThemeMode;
  final ThemeMode themeMode;
  const MainScreen({super.key, required this.updateThemeMode, required this.themeMode});

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
      _themeMode = ThemeMode.values[int.tryParse(prefs['themeMode'] ?? '2') ?? 2];
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
            Image.asset(
              'assets/icon.png',
              width: 32,
              height: 32,
            ),
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