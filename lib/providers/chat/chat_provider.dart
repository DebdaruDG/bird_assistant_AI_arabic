import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:record/record.dart' as record;
import 'package:flutter/services.dart' show rootBundle;
import '../../models/audio_response_model.dart';
import '../../models/chat_model.dart';
import 'chat_state.dart';
import '../../services/websocket_service.dart';
import 'dart:html' as html;

class ChatProvider {
  final ChatState _chatState;
  final WebSocketService _webSocketService;
  final record.AudioRecorder _audioRecorder = record.AudioRecorder();
  final Map<int, String> _chunkedAudioMap = {};

  ChatProvider(this._chatState)
    : _webSocketService = WebSocketService(
        url:
            'wss://73vx4trbb3.execute-api.ap-south-1.amazonaws.com/production/BirdInstructor',
      ) {
    // Connect to WebSocket and set up event listener
    _webSocketService.connect();
    _webSocketService.listenToEvents(
      (message) => _handleResponse(message),
      onError: (error) {
        developer.log('WebSocket error: $error');
        _chatState.updateConnectionStatus(false);
        _chatState.setLoading(false);
        _chatState.setReceivingAudioChunks(false);
      },
      onDone: () {
        developer.log('WebSocket connection closed');
        _chatState.setLoading(false);
        _chatState.setReceivingAudioChunks(false);
      },
    );
  }

  Future<void> sendText(String text) async {
    try {
      _chatState.addChatMessage(ChatMessage(text: text, isUser: true));
      _chatState.addChatMessage(ChatMessage(isUser: false, isLoading: true));
      _chatState.setLoading(true);

      await _webSocketService.sendMessage({
        "action": "TextCompletionOpenaiVoice",
        "text": text,
        "use_assistant": false,
      });
      developer.log('Text event sent successfully');
    } catch (err) {
      developer.log('sendText error: $err');
      _chatState.removeLoadingMessages();
      _chatState.addChatMessage(
        ChatMessage(text: 'Error sending text.', isUser: false),
      );
      _chatState.setLoading(false);
    }
  }

  Future<void> sendAudio(Uint8List audioData) async {
    try {
      _chatState.setLoading(true);
      _chatState.addChatMessage(
        ChatMessage(isUser: true, audioBytes: audioData),
      );
      _chatState.addChatMessage(ChatMessage(isUser: false, isLoading: true));

      String base64Audio = base64Encode(audioData);
      developer.log(
        'base64Audio size: ${(base64Audio.length / 1024.0).toStringAsFixed(3)} KB',
      );

      await sendAudioChunks(base64Audio);
      developer.log('All audio chunks sent successfully');
    } catch (err) {
      developer.log('sendAudio error: $err');
      _chatState.removeLoadingMessages();
      _chatState.addChatMessage(
        ChatMessage(text: 'Error sending audio.', isUser: false),
      );
      _chatState.setLoading(false);
    }
  }

  Future<void> sendAudioChunks(String base64Audio) async {
    const int chunkSizeBytes = 20 * 1024;
    final int totalChunks = (base64Audio.length / chunkSizeBytes).ceil();
    developer.log('Splitting into $totalChunks chunk(s)');

    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSizeBytes;
      final int end = (start + chunkSizeBytes).clamp(0, base64Audio.length);
      final String chunk = base64Audio.substring(start, end);

      final eventOfPunjabiChatBot = {
        "action": "PunjabiChatbot",
        "chunkIndex": i,
        "totalChunks": totalChunks,
        "audio": chunk,
      };

      final eventOfBirdAssistant = {
        "body": {
          "action": "BirdInstructor",
          "chunkIndex": i,
          "totalChunks": totalChunks,
          "audio": chunk,
        },
      };

      await _webSocketService.sendMessage(eventOfBirdAssistant);
      developer.log('Sent chunk ${i + 1}/$totalChunks');

      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  void _handleResponse(dynamic message) {
    try {
      // Handle acknowledgment messages
      if (message is String && message.contains("Sent WebSocket response")) {
        developer.log('Received acknowledgment: $message');
        return;
      }

      // Assume message is already decoded JSON (WebSocketService handles parsing)
      final decoded = message is String ? jsonDecode(message) : message;
      developer.log('Parsed WebSocket response: $decoded');

      if (decoded['action'] == "PunjabiChatbot" && decoded['audio'] != null) {
        int chunkIndex = decoded['chunkIndex'];
        int totalChunks = decoded['totalChunks'];
        String base64Chunk = decoded['audio'];

        _chunkedAudioMap[chunkIndex] = base64Chunk;
        _chatState.setReceivingAudioChunks(true);

        if (_chunkedAudioMap.length == totalChunks) {
          developer.log('All audio chunks received. Reconstructing...');
          String combined = '';
          for (int i = 0; i < totalChunks; i++) {
            if (_chunkedAudioMap[i] == null) {
              developer.log('Missing chunk at index $i');
              _chatState.setReceivingAudioChunks(false);
              _chatState.setLoading(false);
              return;
            }
            combined += _chunkedAudioMap[i]!;
          }

          try {
            Uint8List audioBytes = base64Decode(combined);
            _chatState.removeLoadingMessages();
            _chatState.addChatMessage(
              ChatMessage(audioBytes: audioBytes, isUser: false),
            );

            if (kIsWeb) {
              final blob = html.Blob([audioBytes]);
              final url = html.Url.createObjectUrlFromBlob(blob);
              final audioElement =
                  html.AudioElement()
                    ..src = url
                    ..autoplay = true;
              html.document.body!.append(audioElement);
            }

            _chunkedAudioMap.clear();
            _chatState.setReceivingAudioChunks(false);
            _chatState.setLoading(false);
          } catch (e) {
            developer.log('Error decoding audio: $e');
            _chatState.removeLoadingMessages();
            _chatState.addChatMessage(
              ChatMessage(text: 'Error decoding audio stream.', isUser: false),
            );
            _chatState.setReceivingAudioChunks(false);
            _chatState.setLoading(false);
          }
        }
        return;
      }

      PunjabiBotResponse? punjabiResponse = PunjabiBotResponse.fromJson(
        decoded,
      );
      _chatState.removeLoadingMessages();

      if ((punjabiResponse.audioChunks ?? []).isNotEmpty) {
        for (AudioChunks item in (punjabiResponse.audioChunks ?? [])) {
          final bytes = base64Decode(item.data ?? '');
          _chatState.addChatMessage(
            ChatMessage(audioBytes: Uint8List.fromList(bytes), isUser: false),
          );
        }
      }

      if (decoded['response'] != null) {
        _chatState.addChatMessage(
          ChatMessage(text: decoded['response'], isUser: false),
        );
      }

      if (decoded['audio'] != null) {
        try {
          final bytes = base64Decode(decoded['audio']);
          _chatState.addChatMessage(
            ChatMessage(audioBytes: Uint8List.fromList(bytes), isUser: false),
          );
        } catch (e) {
          developer.log('Error decoding single audio: $e');
          _chatState.addChatMessage(
            ChatMessage(text: 'Error: Failed to decode audio', isUser: false),
          );
        }
      }

      if (decoded['error'] != null) {
        _chatState.addChatMessage(
          ChatMessage(text: 'Error: ${decoded['error']}', isUser: false),
        );
      }

      _chatState.setLoading(false);
      _chatState.setReceivingAudioChunks(false);
    } catch (e) {
      developer.log('Error processing WebSocket response: $e');
      _chatState.setLoading(false);
      _chatState.setReceivingAudioChunks(false);
    }
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        _chatState.setRecording(true);
        if (kIsWeb) {
          await _audioRecorder.start(
            const record.RecordConfig(
              encoder: record.AudioEncoder.wav,
              sampleRate: 16000,
              numChannels: 1,
            ),
            path: '',
          );
          developer.log('Recording started (WAV, memory mode) for Web');
        } else {
          developer.log('Recording not implemented for non-web platforms');
        }
      } else {
        developer.log('Microphone permission denied');
      }
    } catch (err) {
      developer.log('Error starting recording: $err');
      _chatState.setRecording(false);
    }
  }

  Future<void> stopRecording() async {
    try {
      if (_chatState.isRecording) {
        _chatState.setRecording(false);
        final blobUrl = await _audioRecorder.stop();
        if (blobUrl != null && blobUrl.isNotEmpty) {
          final response = await http.get(Uri.parse(blobUrl));
          if (response.statusCode == 200) {
            final audioData = response.bodyBytes;
            developer.log('Recording captured: ${audioData.length} bytes');
            await sendAudio(audioData);
          } else {
            developer.log('HTTP request failed: ${response.statusCode}');
          }
        } else {
          developer.log('No audio data captured');
        }
      }
    } catch (err) {
      developer.log('Error stopping recording: $err');
      _chatState.setRecording(false);
    }
  }

  Future<Uint8List> fetchAssetAudioUint8ListData(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  void dispose() {
    _webSocketService.dispose();
    _audioRecorder.dispose();
  }
}
