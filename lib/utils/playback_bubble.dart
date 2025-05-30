import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app/theme_provider.dart';
import 'app_blurred_bg.dart';
import 'app_color_palette.dart';

class PlaybackBubble extends StatelessWidget {
  final String? transcript;
  final Key? key;
  final VoidCallback? onPlay;
  final bool isStreaming;

  const PlaybackBubble({
    this.transcript,
    this.key,
    this.onPlay,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      blur: 12,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStreaming)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.lightAccent,
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.play_arrow,
                  color: AppColors.darkAssistantBubble,
                ),
                onPressed: onPlay,
              ),
            if (transcript != null)
              Flexible(
                child: Text(
                  transcript!,
                  style: TextStyle(
                    color:
                        Provider.of<ThemeProvider>(context).isDarkMode
                            ? AppColors.lightText
                            : AppColors.darkText,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
