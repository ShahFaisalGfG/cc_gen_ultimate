import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'configuration_service.dart';
import '../ifrastructure/dependency_manager.dart';
import '../../state/logs_state.dart';
import '../../logic/logs_entry.dart';
import '../../ui/widgets/dependency_check_dialog.dart';
import '../../ui/widgets/dependency_install_progress.dart';
import '../../main.dart';

class AppInitializationService {
  final ConfigurationService _configService = ConfigurationService();
  final LogsState _logsState = LogsState();

  LogsState get logsState => _logsState;

  Future<bool> initializeApp(
    BuildContext context,
    VoidCallback onInitialized,
  ) async {
    _logsState.addLog('DEBUG: initializeApp called', level: LogLevel.info);
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
    _logsState.addLog(
      'DEBUG: _showDependencyDialog called',
      level: LogLevel.info,
    );
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
          Navigator.pop(dialogContext); // Close the dependency check dialog
          await _installDependency(
            context,
            dependency,
            onAllComplete: () {
              _logsState.addLog(
                'DEBUG: onAllComplete callback executed',
                level: LogLevel.success,
              );
              onInitialized(); // Call the original callback
              completer.complete(); // Complete the completer
            },
          );
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
    String dependency, {
    VoidCallback? onAllComplete,
  }) async {
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
            showNextButton: true, // Enable next button
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
            // Add callback to install next dependency
            onInstallDependency: (nextDep) async {
              Navigator.pop(context, 'next');
              await _installDependency(context, nextDep);
            },
            // Add callback for when all dependencies are done
            onFinish: () async {
              _logsState.addLog(
                'All dependencies installed successfully.',
                level: LogLevel.success,
              );

              // Check if all dependencies are actually installed
              if (onAllComplete != null) {
                _logsState.addLog(
                  'DEBUG: onAllComplete callback is available, checking final status...',
                  level: LogLevel.info,
                );
                try {
                  final finalStatus = await _configService.checkDependencies();
                  _logsState.addLog(
                    'DEBUG: Final status check result: $finalStatus',
                    level: LogLevel.info,
                  );
                  final allInstalled = finalStatus.values.every(
                    (installed) => installed,
                  );
                  _logsState.addLog(
                    'DEBUG: All dependencies installed: $allInstalled',
                    level: LogLevel.info,
                  );

                  if (allInstalled) {
                    _logsState.addLog(
                      'DEBUG: All dependencies confirmed, calling onAllComplete and closing dialog',
                      level: LogLevel.success,
                    );
                    // Call the completion callback first
                    onAllComplete();
                    // Then close the dialog
                    Navigator.pop(context, 'complete');
                    return;
                  } else {
                    _logsState.addLog(
                      'DEBUG: Not all dependencies installed, falling back to finish',
                      level: LogLevel.warning,
                    );
                  }
                } catch (e) {
                  _logsState.addLog(
                    'Error checking final dependency status: $e',
                    level: LogLevel.error,
                  );
                }
              } else {
                _logsState.addLog(
                  'DEBUG: onAllComplete callback is null',
                  level: LogLevel.warning,
                );
              }

              _logsState.addLog(
                'DEBUG: Falling back to regular finish navigation',
                level: LogLevel.info,
              );
              Navigator.pop(context, 'finish');
            },
          ),
        );

        if (result == 'cancel') {
          shouldContinue = false;
          break;
        } else if (result == 'retry') {
          isRetrying = true;
          continue;
        } else if (result == 'next') {
          // Next dependency installation was triggered, exit this loop
          isRetrying = false;
          break;
        } else if (result == 'finish') {
          // All dependencies are installed, exit this loop
          isRetrying = false;
          break;
        } else if (result == 'complete') {
          // All dependencies are installed and verified, exit without re-checking
          isRetrying = false;
          shouldContinue = false;
          break;
        } else {
          isRetrying = false;
        }
      }

      // Only re-check dependencies if we should continue AND we don't have onAllComplete callback
      if (context.mounted && shouldContinue && onAllComplete == null) {
        // Re-check dependencies after installation only for splash flow
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
            dependencyStatus: status, // Pass current status
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
              await _installDependencyForSplash(
                context,
                nextDep,
                status,
                onSplashComplete,
              );
            },
            onFinish: () {
              _logsState.addLog(
                'All dependencies installed successfully.',
                level: LogLevel.success,
              );
              Navigator.pop(context, 'finish');
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
