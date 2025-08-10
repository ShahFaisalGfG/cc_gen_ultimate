import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../services/configuration_service.dart';
import '../services/dependency_manager.dart';
import '../state/logs_state.dart';
import '../logic/logs.dart';
import '../ui/widgets/dependency_check_dialog.dart';
import '../ui/widgets/dependency_install_progress.dart';
import '../main.dart';

class AppInitializationService {
  final ConfigurationService _configService = ConfigurationService();
  final LogsState _logsState = LogsState();

  LogsState get logsState => _logsState;

  Future<bool> initializeApp(
    BuildContext context,
    VoidCallback onInitialized,
  ) async {
    // Check dependencies
    try {
      final status = await _configService.checkDependencies();
      final allDependenciesInstalled = status.values.every(
        (installed) => installed,
      );

      for (var entry in status.entries) {
        _logsState.addLog(
          '${entry.key}: ${entry.value ? "Installed ✓" : "Not installed ✗"}',
          level: entry.value ? LogLevel.success : LogLevel.warning,
        );
      }

      if (!allDependenciesInstalled && context.mounted) {
        _logsState.addLog(
          'Missing dependencies detected. Installation required.',
          level: LogLevel.warning,
        );
        final completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDependencyDialog(context, status, completer, onInitialized);
        });

        await completer.future;
        return false;
      } else {
        _logsState.addLog(
          'All dependencies are installed.',
          level: LogLevel.success,
        );
        return true;
      }
    } catch (e) {
      _logsState.addLog(
        'Error checking dependencies: $e',
        level: LogLevel.error,
      );
      if (context.mounted) {
        final completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog(context, completer, onInitialized);
        });
        await completer.future;
        return false;
      }
    }
    return false;
  }

  Future<bool> checkDependenciesForSplash(
    BuildContext context,
    VoidCallback onSplashComplete,
  ) async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      onSplashComplete();
      return true;
    }

    _logsState.addLog('Starting dependency check...');
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return false;

    try {
      final status = await _configService.checkDependencies();
      final allDependenciesInstalled = status.values.every(
        (installed) => installed,
      );

      for (var entry in status.entries) {
        _logsState.addLog(
          '${entry.key}: ${entry.value ? "Installed ✓" : "Not installed ✗"}',
          level: entry.value ? LogLevel.success : LogLevel.warning,
        );
      }

      if (!allDependenciesInstalled && context.mounted) {
        _logsState.addLog(
          'Missing dependencies detected. Installation required.',
          level: LogLevel.warning,
        );
        final completer = Completer<void>();
        await _showDependencyDialogForSplash(
          context,
          status,
          completer,
          onSplashComplete,
        );
        completer.complete();
        return false;
      } else {
        _logsState.addLog(
          'All dependencies are installed.',
          level: LogLevel.success,
        );
        onSplashComplete();
        return true;
      }
    } catch (e) {
      _logsState.addLog(
        'Error checking dependencies: $e',
        level: LogLevel.error,
      );
      if (!context.mounted) return false;

      final completer = Completer<void>();
      await _showErrorDialogForSplash(context, completer, onSplashComplete);
      completer.complete();
      return false;
    }
  }

  void _showDependencyDialog(
    BuildContext context,
    Map<String, bool> status,
    Completer<void> completer,
    VoidCallback onInitialized,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DependencyCheckDialog(
        initialStatus: status,
        logsState: _logsState,
        onRetryPressed: () {
          _logsState.addLog('Retrying dependency check...');
          Navigator.pop(dialogContext);
          initializeApp(context, onInitialized);
          completer.complete();
        },
        onClosePressed: () {
          _logsState.addLog(
            'Dependency check skipped by user.',
            level: LogLevel.warning,
          );
          Navigator.pop(dialogContext);
          completer.complete();
        },
        showInstallButton: status['python']! && !status.values.every((v) => v),
        onInstallDependency: (dependency) async {
          await _installDependency(context, dependency);
        },
      ),
    );
  }

  void _showErrorDialog(
    BuildContext context,
    Completer<void> completer,
    VoidCallback onInitialized,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DependencyCheckDialog(
        initialStatus: {},
        logsState: _logsState,
        onRetryPressed: () {
          _logsState.addLog('Retrying after error...');
          Navigator.pop(dialogContext);
          initializeApp(context, onInitialized);
          completer.complete();
        },
        onClosePressed: () {
          _logsState.addLog(
            'Check aborted after error.',
            level: LogLevel.error,
          );
          Navigator.pop(dialogContext);
          completer.complete();
        },
        showInstallButton: false,
      ),
    );
  }

  Future<void> _showDependencyDialogForSplash(
    BuildContext context,
    Map<String, bool> status,
    Completer<void> completer,
    VoidCallback onSplashComplete,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DependencyCheckDialog(
        initialStatus: status,
        logsState: _logsState,
        onRetryPressed: () {
          _logsState.addLog('Retrying dependency check...');
          Navigator.pop(dialogContext);
          checkDependenciesForSplash(context, onSplashComplete);
          completer.complete();
        },
        onClosePressed: () {
          _logsState.addLog(
            'Dependency check skipped by user.',
            level: LogLevel.warning,
          );
          Navigator.pop(dialogContext);
          onSplashComplete();
          completer.complete();
        },
        showInstallButton: status['python']! && !status.values.every((v) => v),
        onInstallDependency: (dependency) async {
          await _installDependencyForSplash(
            context,
            dependency,
            status,
            onSplashComplete,
          );
        },
      ),
    );
  }

  Future<void> _showErrorDialogForSplash(
    BuildContext context,
    Completer<void> completer,
    VoidCallback onSplashComplete,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DependencyCheckDialog(
        initialStatus: {},
        logsState: _logsState,
        onRetryPressed: () {
          _logsState.addLog('Retrying after error...');
          Navigator.pop(dialogContext);
          checkDependenciesForSplash(context, onSplashComplete);
          completer.complete();
        },
        onClosePressed: () {
          _logsState.addLog(
            'Check aborted after error.',
            level: LogLevel.error,
          );
          Navigator.pop(dialogContext);
          onSplashComplete();
          completer.complete();
        },
        showInstallButton: false,
      ),
    );
  }

  Future<void> _installDependency(
    BuildContext context,
    String dependency,
  ) async {
    try {
      final dependencyManager = DependencyManager();
      bool isRetrying = true;
      bool shouldContinue = true;

      while (isRetrying && shouldContinue && context.mounted) {
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
            logsStream: dependencyManager.installDependency(dependency).map((
              step,
            ) {
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
              _logsState.addLog(
                'Installation cancelled by user.',
                level: LogLevel.warning,
              );
              Navigator.pop(context, 'cancel');
            },
            onRetryPressed: () {
              _logsState.addLog(
                'Retrying installation of $dependency...',
                level: LogLevel.info,
              );
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

      if (context.mounted && shouldContinue) {
        // Re-check dependencies after installation
        checkDependenciesForSplash(context, () {});
      }
    } catch (e) {
      _logsState.addLog(
        'Failed to install $dependency: $e',
        level: LogLevel.error,
      );
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to install $dependency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _installDependencyForSplash(
    BuildContext context,
    String dependency,
    Map<String, bool> status,
    VoidCallback onSplashComplete,
  ) async {
    try {
      final dependencyManager = DependencyManager();
      bool isRetrying = true;
      bool shouldContinue = true;

      while (isRetrying && shouldContinue && context.mounted) {
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
            logsStream: dependencyManager.installDependency(dependency).map((
              step,
            ) {
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
              _logsState.addLog(
                'Installation cancelled by user.',
                level: LogLevel.warning,
              );
              Navigator.pop(context, 'cancel');
            },
            onRetryPressed: () {
              _logsState.addLog(
                'Retrying installation of $dependency...',
                level: LogLevel.info,
              );
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
                  logsStream: dependencyManager
                      .installDependency(nextDep)
                      .map((step) => step.logs ?? step.details),
                  onInstallDependency: (nextDep) async {
                    Navigator.pop(context);
                    await checkDependenciesForSplash(context, onSplashComplete);
                  },
                  onFinish: () {
                    _logsState.addLog(
                      'All dependencies installed successfully.',
                      level: LogLevel.success,
                    );
                    checkDependenciesForSplash(context, onSplashComplete);
                  },
                ),
              );
            },
            onFinish: () {
              _logsState.addLog(
                'All dependencies installed successfully.',
                level: LogLevel.success,
              );
              checkDependenciesForSplash(context, onSplashComplete);
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

      if (context.mounted && shouldContinue) {
        checkDependenciesForSplash(context, onSplashComplete);
      }
    } catch (e) {
      _logsState.addLog(
        'Failed to install $dependency: $e',
        level: LogLevel.error,
      );
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to install $dependency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
