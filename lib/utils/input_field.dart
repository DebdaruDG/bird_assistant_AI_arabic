import 'package:bird_instructor/utils/app_blurred_bg.dart';
import 'package:bird_instructor/utils/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat/chat_state.dart';
import '../providers/chat/chat_provider.dart';

class InputSection extends StatelessWidget {
  const InputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer<ChatState>(
        builder: (context, chatState, child) {
          final chatProvider = context.read<ChatProvider>();
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(color: AppColors.darkAssistantBubble),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      chatProvider.sendText(value.trim());
                      textController.clear();
                    }
                  },
                  enabled: !chatState.isRecording && !chatState.isLoading,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    hintText:
                        chatState.isRecording
                            ? 'Recording...'
                            : 'Type a message...',
                    hintStyle: const TextStyle(color: Colors.black45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: GlassmorphismCard(
                        blur: 12,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(
                            Icons.send,
                            color: AppColors.darkAssistantBubble,
                            size: 20,
                          ),
                        ),
                      ),
                      onPressed:
                          chatState.isRecording || chatState.isLoading
                              ? null
                              : () {
                                if (textController.text.trim().isNotEmpty) {
                                  chatProvider.sendText(
                                    textController.text.trim(),
                                  );
                                  textController.clear();
                                }
                              },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  chatState.isRecording ? Icons.stop : Icons.mic,
                  size: 20,
                  color: chatState.isRecording ? Colors.red : Colors.grey[600],
                ),
                onPressed:
                    chatState.isLoading
                        ? null
                        : () {
                          if (chatState.isRecording) {
                            chatProvider.stopRecording();
                          } else {
                            chatProvider.startRecording();
                          }
                        },
              ),
            ],
          );
        },
      ),
    );
  }
}
