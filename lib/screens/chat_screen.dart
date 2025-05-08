import 'dart:developer';

import 'package:bird_instructor/utils/app_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../models/chat_model.dart';
import '../providers/app/theme_provider.dart';
import '../providers/chat/chat_state.dart';
import '../utils/app_blurred_bg.dart';
import '../utils/app_text.dart';
import '../utils/custom_paints/sun_moon.dart';
import '../utils/input_field.dart';
import '../utils/playback_bubble.dart';
import '../utils/typing_indicator.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder:
          (context, themeState, _) => Scaffold(
            backgroundColor:
                themeState.isDarkMode
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor:
                  themeState.isDarkMode
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
              elevation: 0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/images/falcon_logo.svg', height: 30),
                  const SizedBox(width: 8),
                  AppText(
                    'Falcon',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color:
                          themeState.isDarkMode
                              ? AppColors.darkText
                              : AppColors.lightText,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                    icon: Icon(
                      themeState.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color:
                          themeState.isDarkMode
                              ? AppColors.lightBackground
                              : AppColors.darkBackground,
                    ),
                    onPressed: () {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme();
                    },
                  ),
                ),
              ],
            ),
            body: Consumer<ChatState>(
              builder: (context, chatState, child) {
                return Column(
                  children: [
                    if (!chatState.isConnected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        color: Colors.redAccent.withOpacity(0.8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            AppText(
                              'Disconnected. Reconnecting...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (chatState.chats.isEmpty)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSunMoonWidget(key: key),
                            AppText(
                              'Say something to begin ...',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color:
                                    themeState.isDarkMode
                                        ? AppColors.lightBackground
                                        : AppColors.darkBackground,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          reverse: true, // Newest messages at the bottom
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          itemCount: chatState.chats.length,
                          itemBuilder: (context, index) {
                            log('chatState.isLoading - ${chatState.isLoading}');
                            final message =
                                chatState.chats[chatState.chats.length -
                                    1 -
                                    index];

                            return _buildAudioMessage(
                              context,
                              message,
                              chatState,
                            );
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
                      child: GlassmorphismCard(
                        blur: 12.0,
                        child: InputSection(),
                      ),
                    ),
                  ],
                );
              },
            ),
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

    if (chatState.isLoading) {
      return TypingIndicator();
    }

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
