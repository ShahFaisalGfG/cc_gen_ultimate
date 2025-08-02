import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectableLogsView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? scrollController;
  final String? copyText;

  const SelectableLogsView({
    super.key,
    required this.children,
    this.scrollController,
    this.copyText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: () {
        if (copyText != null) {
          _showContextMenu(context);
        }
      },
      child: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: MaterialTextSelectionControls(),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: const Text('Copy All'),
          onTap: () {
            if (copyText != null) {
              Clipboard.setData(ClipboardData(text: copyText!));
            }
          },
        ),
      ],
    );
  }
}
