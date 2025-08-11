import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About CC Gen Ultimate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/icon.png',
              width: 64,
              height: 64,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Author: Shah Faisal'),
          const Text('Publisher/Company: gfgRoyal'),
          const Text('GitHub: ShahFaisalGFG'),
          const SizedBox(height: 12),
          const Text('CC Gen Ultimate is a cross-platform app for generating and translating subtitles using Whisper AI and LibreTranslate.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
