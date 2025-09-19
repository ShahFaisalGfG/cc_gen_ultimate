import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/logs_state.dart';
import '../../logic/logs_entry.dart';
import '../../services/ifrastructure/dependency_manager.dart';
import 'logs_widget/logs_panel.dart';

class DependencyInstallProgress extends StatefulWidget {
  final String currentStep;
  final int totalSteps;
  final int currentStepIndex;
  final String details;
  final Stream<String>? logsStream;
  final LogsState logsState;
  final VoidCallback? onCancelPressed;
  final VoidCallback? onRetryPressed;
  final bool showInstallButton;
  final bool showNextButton;
  final Function(String)? onInstallDependency;
  final VoidCallback? onFinish;
  final Map<String, bool>? dependencyStatus; // Add this to track current status

  const DependencyInstallProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.currentStepIndex,
    required this.details,
    required this.logsState,
    this.logsStream,
    this.onCancelPressed,
    this.onRetryPressed,
    this.showInstallButton = false,
    this.showNextButton = false,
    this.onInstallDependency,
    this.onFinish,
    this.dependencyStatus,
  });

  @override
  State<DependencyInstallProgress> createState() =>
      _DependencyInstallProgressState();
}

class _DependencyInstallProgressState extends State<DependencyInstallProgress> {
  bool _showLogs = true;
  bool _isCancelled = false;
  bool _isError = false;
  String? _errorMessage;
  double? _progress;
  StreamSubscription<String>? _logsSubscription;
  final DependencyManager _dependencyManager = DependencyManager();

  String _getDependencyDisplayName(String key) {
    switch (key) {
      case 'python':
        return 'Python 3.8, 3.9, 3.10, or 3.11';
      case 'pip':
        return 'pip (Package Installer)';
      case 'faster-whisper':
        return 'Faster Whisper';
      case 'libretranslate':
        return 'libretranslate';
      case 'ffmpeg':
        return 'FFmpeg';
      default:
        return key;
    }
  }

  Future<String?> _getNextMissingDependency() async {
    try {
      // Always fetch fresh dependency status to get the most up-to-date information
      // The status passed to the widget might be stale after installation completes
      final status = await _dependencyManager.getDependencyStatus();

      // Use helper method from dependency manager to get next missing dependency
      final nextDep = _dependencyManager.getNextMissingDependency(
        status,
        widget.currentStep,
      );

      return nextDep;
    } catch (e) {
      widget.logsState.addLog(
        'Error checking dependencies: $e',
        level: LogLevel.error,
      );
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupLogsListener();
  }

  @override
  void dispose() {
    _cancelInstallation();
    super.dispose();
  }

  void _cancelInstallation() {
    // Only show the abort message if we're actually cancelling (not transitioning)
    if (!_isCancelled && (_progress == null || _progress! < 1.0)) {
      _isCancelled = true;
      _logsSubscription?.cancel();
      widget.logsState.addLog('Installation aborted.', level: LogLevel.error);
    } else {
      // Just clean up the subscription without showing the message
      _logsSubscription?.cancel();
    }
  }

  LogLevel _getLogLevel(String log) {
    final lowercaseLog = log.toLowerCase();
    if (lowercaseLog.contains('failed') || lowercaseLog.contains('error')) {
      return LogLevel.error;
    } else if (lowercaseLog.contains('uninstalled') ||
        lowercaseLog.contains('uninstalled successfully')) {
      return LogLevel.warning;
    } else if (lowercaseLog.contains('success') ||
        lowercaseLog.contains('completed') ||
        lowercaseLog.contains('installation successful') ||
        lowercaseLog.contains('installed')) {
      return LogLevel.success;
    }
    return LogLevel.info;
  }

  void _setupLogsListener() {
    _logsSubscription?.cancel();
    if (widget.logsStream != null) {
      _logsSubscription = widget.logsStream!.listen(
        (log) {
          final level = _getLogLevel(log);
          // Only add colored logs (error, warning, success) to avoid duplication
          if (level != LogLevel.info) {
            widget.logsState.addLog(log, level: level);
          }
          if (level == LogLevel.error) {
            setState(() {
              _isError = true;
              _errorMessage = log;
              _progress = null;
            });
          } else if (level == LogLevel.success ||
              (log.toLowerCase().contains('installation successful') ||
                  log.toLowerCase().contains('installation completed'))) {
            // Debug log: widget.logsState.addLog('Success detected - Setting progress to 1.0', level: LogLevel.info);
            setState(() {
              _progress = 1.0;
              _isError = false;
            });
            // Debug info about next dependency (commented for production)
            // final nextDep = _getNextMissingDependency();
            // widget.logsState.addLog(
            //   'Next dependency: ${nextDep ?? "none"}, Can install: ${widget.onInstallDependency != null}',
            //   level: LogLevel.info
            // );
          } else {
            setState(() {
              _progress = (_progress ?? 0.0) + 0.1;
              if (_progress! > 0.9) _progress = 0.9;
            });
          }
        },
        onError: (e) {
          widget.logsState.addLog('Stream error: $e', level: LogLevel.error);
          setState(() {
            _isError = true;
            _errorMessage = 'Unexpected error: $e';
            _progress = null;
          });
        },
        onDone: () {
          if (!_isCancelled && !_isError) {
            widget.logsState.addLog(
              '${widget.currentStep} installation completed.',
              level: LogLevel.success,
            );
            setState(() {
              _progress = 1.0;
              _isError = false;
            });
            // Debug info about installation completion (commented for production)
            // final nextDep = _getNextMissingDependency();
            // widget.logsState.addLog(
            //   'Installation complete. Next dependency: ${nextDep ?? "none"}, Can install: ${widget.onInstallDependency != null}',
            //   level: LogLevel.info
            // );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Installing ${widget.currentStep} (${widget.currentStepIndex}/${widget.totalSteps})',
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() => _showLogs = !_showLogs);
            },
            icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
            label: Text(_showLogs ? 'Hide Logs' : 'Show Logs'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step: ${_getDependencyDisplayName(widget.currentStep)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(widget.details),
            const SizedBox(height: 16),
            if (_progress != null)
              LinearProgressIndicator(
                value: _progress,
                color: _isError ? theme.colorScheme.error : theme.primaryColor,
              ),
            if (_showLogs) ...[
              const SizedBox(height: 8),
              ChangeNotifierProvider.value(
                value: widget.logsState,
                child: LogsPanel(showLogs: true),
              ),
            ],
            if (_isError && _errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCancelled || _progress == 1.0
              ? null
              : () async {
                  _cancelInstallation();
                  Navigator.of(context, rootNavigator: true).pop();
                  widget.onCancelPressed?.call();
                },
          child: const Text('Cancel'),
        ),
        if (_isError && widget.onRetryPressed != null)
          TextButton(
            onPressed: _isCancelled ? null : widget.onRetryPressed,
            child: const Text('Retry'),
          ),
        if (!_isError && _progress == 1.0) ...[
          // Dynamic buttons based on next missing dependency
          FutureBuilder<String?>(
            future: _getNextMissingDependency(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final nextDep = snapshot.data;

              if (nextDep != null && widget.onInstallDependency != null) {
                // Show "Install Next Dependency" button
                return ElevatedButton(
                  onPressed: () {
                    _logsSubscription
                        ?.cancel(); // Cancel subscription without marking as aborted
                    Navigator.pop(context);
                    widget.onInstallDependency?.call(nextDep);
                  },
                  child: Text('Install ${_getDependencyDisplayName(nextDep)}'),
                );
              } else if (widget.onFinish != null) {
                // Show "Finish" button if no more dependencies
                return ElevatedButton(
                  onPressed: () {
                    // Since the "Finish" button only appears when all dependencies are installed,
                    // we can proceed directly without re-checking
                    widget.logsState.addLog(
                      'All dependencies installation completed. Proceeding to main screen...',
                      level: LogLevel.success,
                    );

                    // Close this dialog and proceed
                    Navigator.pop(context);
                    widget.onFinish?.call();
                  },
                  child: const Text('Finish'),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
        if (widget.showInstallButton)
          ElevatedButton(
            onPressed: _isCancelled ? null : () => Navigator.pop(context),
            child: const Text('Install'),
          ),
      ],
    );
  }
}
