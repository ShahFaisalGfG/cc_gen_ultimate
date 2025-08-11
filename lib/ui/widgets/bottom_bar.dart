import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final int selectedTab;
  final Widget tabBarContent;
  final Widget? logsPanel;
  final Function(int) onTabChanged;

  const BottomBar({
    super.key,
    required this.selectedTab,
    required this.tabBarContent,
    this.logsPanel,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tabBarContent,
        if (logsPanel != null) logsPanel!,
        BottomNavigationBar(
          currentIndex: selectedTab,
          onTap: onTabChanged,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.subtitles),
              label: 'Generate CC',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.translate),
              label: 'Translate CC',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.model_training),
              label: 'Models',
            ),
          ],
        ),
      ],
    );
  }
}
