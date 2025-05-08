import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_model.dart';
import '../providers/chat/chat_state.dart';
import '../utils/app_blurred_bg.dart';
import '../utils/input_field.dart';
import '../utils/playback_bubble.dart';
import '../utils/typing_indicator.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background like Grok
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FalconSpeak',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: Consumer<ChatState>(
        builder: (context, chatState, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // Newest messages at the bottom
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  itemCount: chatState.chats.length,
                  itemBuilder: (context, index) {
                    final message =
                        chatState.chats[chatState.chats.length - 1 - index];
                    return _buildAudioMessage(context, message, chatState);
                  },
                ),
              ),
              if (chatState.isLoading || chatState.isReceivingAudioChunks)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: TypingIndicator(),
                ),
              Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 6,
                ),
                child: GlassmorphismCard(blur: 12.0, child: InputSection()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAudioMessage(
    BuildContext context,
    ChatMessage message,
    ChatState chatState,
  ) {
    final isUser = message.isUser;
    final audioBytes = message.audioBytes;

    if (audioBytes == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: PlaybackBubble(
        transcript: message.text,
        key: key,
        onPlay: () => chatState.togglePlayPause(audioBytes),
      ),
    );
  }
}
