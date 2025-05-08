import 'package:flutter/material.dart';

import 'app_color_palette.dart';

class PlaybackBubble extends StatelessWidget {
  final String? transcript;
  final VoidCallback onPlay;

  const PlaybackBubble({super.key, this.transcript, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkAssistantBubble
            : AppColors.lightAssistantBubble;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(onPressed: onPlay, icon: const Icon(Icons.volume_up)),
          if (transcript != null) ...[
            const SizedBox(height: 8),
            Text(transcript!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
