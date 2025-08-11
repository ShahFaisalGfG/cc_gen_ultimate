import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../state/logs_state.dart';
import '../../services/ifrastructure/dependency_manager.dart';
import '../../logic/logs_entry.dart';
import 'logs_widget/logs_panel.dart';

class DependencyCheckDialog extends StatefulWidget {
  final Map<String, bool> initialStatus;
  final LogsState logsState;
  final VoidCallback onRetryPressed;
  final VoidCallback onClosePressed;
  final bool showInstallButton;
  final Function(String)? onInstallDependency;

  const DependencyCheckDialog({
    super.key,
    required this.initialStatus,
    required this.logsState,
    required this.onRetryPressed,
    required this.onClosePressed,
    this.showInstallButton = false,
    this.onInstallDependency,
  });

  @override
  State<DependencyCheckDialog> createState() => _DependencyCheckDialogState();
}

class _DependencyCheckDialogState extends State<DependencyCheckDialog> {
  late Map<String, bool> status;
  bool _showLogs = false;
  bool _isChecking = false;
  bool _isInstalling = false;

  // Ordered sequence of dependencies
  static const List<String> dependencySequence = [
    'python',
    'pip',
    'ffmpeg',
    'faster-whisper',
    'libretranslate',
  ];

  @override
  void initState() {
    super.initState();
    status = Map.from(widget.initialStatus);
  }

  String _getDependencyDisplayName(String key) {
    switch (key) {
      case 'python':
        return 'Python 3.8+';
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

  String? _getNextMissingDependency() {
    for (var dep in dependencySequence) {
      final depStatus = status[dep];
      if (depStatus == null || !depStatus) {
        return dep;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextDependency = _getNextMissingDependency();

    return AlertDialog(
      title: Text('Dependency Check', style: theme.textTheme.titleLarge),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CC Gen Ultimate requires the following dependencies:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_isChecking) const LinearProgressIndicator(),
            if (!_isChecking) ...[
              ...dependencySequence.map((dep) {
                final isInstalled = status[dep] ?? false;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isInstalled ? Icons.check_circle : Icons.cancel,
                        color: isInstalled ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDependencyDisplayName(dep),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (status['python'] != true) ...[
                const SizedBox(height: 16),
                const Text(
                  'Python 3.8 or higher is required.\n'
                  'Python 3.10 is recommended for optimal compatibility.\n'
                  'If a newer version is installed, consider downgrading to Python 3.10.\n\n'
                  '- Silent Install: Automatically installs Python 3.10\n(administrator privileges required).\n'
                  '- Manual Download: Download and install Python 3.10 manually\n(user-only installation available).',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(
                    _showLogs ? Icons.visibility_off : Icons.visibility,
                  ),
                  label: Text(_showLogs ? 'Hide Logs' : 'Show Logs'),
                  onPressed: () {
                    setState(() => _showLogs = !_showLogs);
                  },
                ),
              ],
            ),
            if (_showLogs) ...[
              const SizedBox(height: 8),
              ChangeNotifierProvider.value(
                value: widget.logsState,
                child: LogsPanel(showLogs: true),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isChecking && !status['python']!) ...[
          TextButton(
            onPressed: () async {
              final url = Uri.parse(
                'https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
                widget.logsState.addLog(
                  'Opened Python download page.',
                  level: LogLevel.info,
                );
              } else {
                widget.logsState.addLog(
                  'Failed to open Python download page.',
                  level: LogLevel.error,
                );
              }
            },
            child: const Text('Manually Download Python'),
          ),
          ElevatedButton(
            onPressed: _isInstalling
                ? null
                : () {
                    setState(() => _isInstalling = true);
                    widget.logsState.addLog(
                      'Starting silent Python installation...',
                      level: LogLevel.info,
                    );
                    widget.onInstallDependency?.call('python');
                  },
            child: const Text('Silent Install Python'),
          ),
        ],
        if (!_isChecking &&
            widget.showInstallButton &&
            widget.onInstallDependency != null &&
            status['python']! &&
            nextDependency != null)
          ElevatedButton(
            onPressed: _isInstalling
                ? null
                : () {
                    setState(() => _isInstalling = true);
                    widget.logsState.addLog(
                      'Starting installation of ${_getDependencyDisplayName(nextDependency)}...',
                      level: LogLevel.info,
                    );
                    widget.onInstallDependency?.call(nextDependency);
                  },
            child: Text('Install ${_getDependencyDisplayName(nextDependency)}'),
          ),
        if (!_isChecking)
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
            onPressed: _isInstalling
                ? null
                : () async {
                    setState(() {
                      _isChecking = true;
                      _isInstalling = false;
                    });
                    widget.logsState.addLog(
                      'Checking dependencies again...',
                      level: LogLevel.info,
                    );
                    try {
                      final newStatus = await DependencyManager()
                          .getDependencyStatus();
                      setState(() {
                        status = newStatus;
                        _isChecking = false;
                      });
                      widget.onRetryPressed();
                    } catch (e) {
                      widget.logsState.addLog(
                        'Error re-checking dependencies: $e',
                        level: LogLevel.error,
                      );
                      setState(() => _isChecking = false);
                    }
                  },
          ),
      ],
    );
  }
}
