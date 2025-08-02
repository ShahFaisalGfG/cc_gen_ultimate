import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../state/logs_state.dart';
import '../../logic/logs.dart';

class LogsPanel extends StatelessWidget {
  final bool showLogs;

  const LogsPanel({
    super.key,
    required this.showLogs,
  });

  @override
  Widget build(BuildContext context) {
    if (!showLogs) return const SizedBox.shrink();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Consumer<LogsState>(
        builder: (context, logsState, child) {
          final fullText = logsState.logs.map((log) {
            final timestamp = '[${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}]';
            return '$timestamp ${log.message}';
          }).join('\n');

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('Logs Panel'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_all),
                      tooltip: 'Copy All',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullText));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: () {
                        context.read<LogsState>().clear();
                      },
                      tooltip: 'Clear logs',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onSecondaryTapUp: (details) {
                    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                    showMenu(
                      context: context,
                      position: RelativeRect.fromRect(
                        details.globalPosition & const Size(48.0, 48.0),
                        Offset.zero & overlay.size,
                      ),
                      items: [
                        PopupMenuItem(
                          child: const Text('Copy All'),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: fullText));
                          },
                        ),
                      ],
                    );
                  },
                  child: SelectableRegion(
                    focusNode: FocusNode(),
                    selectionControls: MaterialTextSelectionControls(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text.rich(
                        TextSpan(
                          children: logsState.logs.map((log) {
                            return TextSpan(
                              children: [
                                TextSpan(
                                  text: '[${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}] ',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                TextSpan(
                                  text: '${log.message}\n',
                                  style: TextStyle(
                                    color: _getColorForLevel(context, log.level),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        style: const TextStyle(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getColorForLevel(BuildContext context, LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Theme.of(context).colorScheme.error;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.info:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
}
