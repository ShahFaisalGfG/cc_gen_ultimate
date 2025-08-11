import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogViewBase extends StatelessWidget {
  final List<Widget> toolbarActions;
  final Widget title;
  final Widget logContent;
  final String fullText;

  const LogViewBase({
    super.key,
    required this.toolbarActions,
    required this.title,
    required this.logContent,
    required this.fullText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
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
              title,
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy_all',
                    child: Text('Copy All'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'copy_all') {
                    Clipboard.setData(ClipboardData(text: fullText));
                  }
                },
              ),
              ...toolbarActions,
            ],
          ),
        ),
        // Log content
        Expanded(
          child: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: MaterialTextSelectionControls(),
            child: logContent,
          ),
        ),
      ],
    );
  }
}
