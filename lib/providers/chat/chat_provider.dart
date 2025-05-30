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
  html.AudioElement? _audioElement;
  String? _currentAudioMessageId;
  List<int> _combinedAudioBytes = [];
  int? _firstChunkReceivedTime;
  int? _chunkSendStartTime;
  html.MediaSource? _mediaSource;
  html.SourceBuffer? _sourceBuffer;
  bool _isMediaSourceOpen = false;
  final List<Uint8List> _audioChunkQueue = [];
  bool _isProcessingQueue = false;

  ChatProvider(this._chatState)
    : _webSocketService = WebSocketService(
        url:
            'wss://pu6niet7nl.execute-api.ap-south-1.amazonaws.com/production/',
      ) {
    _webSocketService.connect();
    _webSocketService.listenToEvents(
      (message) => _handleResponse(message),
      onError: (error) {
        developer.log('WebSocket error: $error');
        _chatState.setLoading(false);
        _chatState.setReceivingAudioChunks(false);
        _stopPlayback();
      },
      onDone: () {
        developer.log('WebSocket connection closed');
        _chatState.setLoading(false);
        _chatState.setReceivingAudioChunks(false);
        _stopPlayback();
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
      Future.delayed(Duration.zero, () async {
        _chatState.setLoading(true);
        _chatState.addChatMessage(
          ChatMessage(isUser: true, audioBytes: audioData),
        );
        _chatState.addChatMessage(ChatMessage(isUser: false, isLoading: true));

        String base64Audio = base64Encode(audioData);
        developer.log(
          'base64Audio size: ${(base64Audio.length / 1024.0).toStringAsFixed(3)} KB',
        );

        final sendStartTime = DateTime.now().millisecondsSinceEpoch;
        developer.log(
          'Timelog - Start sending to WebSocket at: $sendStartTime ms',
        );

        await sendAudioChunks(base64Audio);

        final sendEndTime = DateTime.now().millisecondsSinceEpoch;
        developer.log(
          'Timelog - Finished sending to WebSocket at: $sendEndTime ms',
        );
        final sendDuration = sendEndTime - sendStartTime;
        developer.log(
          'Timelog - Time to send to WebSocket: ${sendDuration / 1000} seconds',
        );

        _chatState.setSendEndTime(sendEndTime);
        _chatState.setMicOpenTime(sendStartTime);
      });
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

    _chunkSendStartTime = DateTime.now().millisecondsSinceEpoch;
    developer.log(
      'Timelog - Chunk sending started at: $_chunkSendStartTime ms',
    );

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
        "action": "BirdInstructor",
        "chunkIndex": i,
        "totalChunks": totalChunks,
        "audio": chunk,
      };

      await _webSocketService.sendMessage(eventOfBirdAssistant);
      developer.log('Sent chunk ${i + 1}/$totalChunks');

      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  void _handleResponse(dynamic message) {
    developer.log('message - $message');
    if (message is String && message.contains("Sent WebSocket response")) {
      developer.log('Received acknowledgment: $message');
      return;
    }

    final decoded = message is String ? jsonDecode(message) : message;
    developer.log(
      'Parsed WebSocket response: $decoded , type - ${decoded.runtimeType}',
    );

    if (decoded is Map && decoded.containsKey('error')) {
      final error = decoded['error'];
      final errorMessage =
          error is Map && error.containsKey('message')
              ? error['message']
              : 'Unknown error';
      developer.log('errorMessage: $errorMessage');
      _chatState.addChatMessage(
        ChatMessage(
          audioBytes: null,
          isUser: false,
          text: errorMessage,
          isLoading: _chatState.isLoading,
        ),
      );
      _chatState.setReceivingAudioChunks(false);
      _chatState.setLoading(false);
      _stopPlayback();
      return;
    } else if (decoded['action'] == 'BirdInstructorAudio') {
      int chunkIndex = decoded['chunkIndex'];
      String base64Chunk = decoded['audio'];
      bool isFinal = decoded['isFinal'] ?? false;
      int totalChunks = decoded['totalChunks'] ?? -1;

      _chunkedAudioMap[chunkIndex] = base64Chunk;

      if (base64Chunk.trim().isNotEmpty) {
        try {
          final chunkBytes = base64Decode(base64Chunk);
          _combinedAudioBytes.addAll(chunkBytes);
          _audioChunkQueue.add(chunkBytes);
          developer.log(
            'Received chunk $chunkIndex, Queue size: ${_audioChunkQueue.length}, '
            'Total bytes: ${_combinedAudioBytes.length}',
          );

          if (_currentAudioMessageId == null) {
            _firstChunkReceivedTime = DateTime.now().millisecondsSinceEpoch;
            developer.log(
              'Timelog - First chunk received at: $_firstChunkReceivedTime ms',
            );

            if (_chunkSendStartTime != null) {
              final duration = _firstChunkReceivedTime! - _chunkSendStartTime!;
              developer.log(
                'Timelog - Duration from chunk send to first chunk received: ${duration / 1000} seconds',
              );
              _chunkSendStartTime = null;
            }

            _currentAudioMessageId =
                DateTime.now().millisecondsSinceEpoch.toString();
            _initializeMediaSource();
            _chatState.addChatMessage(
              ChatMessage(
                audioBytes: Uint8List.fromList(_combinedAudioBytes),
                isUser: false,
                isStreaming: true,
                id: _currentAudioMessageId,
              ),
            );
            _chatState.setReceivingAudioChunks(true);
          } else {
            _chatState.updateChatMessage(
              _currentAudioMessageId!,
              ChatMessage(
                audioBytes: Uint8List.fromList(_combinedAudioBytes),
                isUser: false,
                isStreaming: !isFinal,
                id: _currentAudioMessageId,
              ),
            );
          }

          _processAudioQueue();
        } catch (e) {
          developer.log('❌ Base64 decode failed on chunk $chunkIndex: $e');
        }
      }

      if (isFinal && totalChunks > 0 && _chunkedAudioMap.length < totalChunks) {
        developer.log(
          'Warning: Received isFinal but only ${_chunkedAudioMap.length}/$totalChunks chunks received',
        );
        return;
      }

      if (isFinal) {
        developer.log(
          '✅ All chunks received. Bytes count: ${_combinedAudioBytes.length}',
        );

        if (_combinedAudioBytes.isNotEmpty && _currentAudioMessageId != null) {
          _chatState.updateChatMessage(
            _currentAudioMessageId!,
            ChatMessage(
              audioBytes: Uint8List.fromList(_combinedAudioBytes),
              isUser: false,
              isStreaming: false,
              id: _currentAudioMessageId,
            ),
          );
        }

        void finalizeStream() {
          if (_audioChunkQueue.isEmpty &&
              _isMediaSourceOpen &&
              _sourceBuffer != null &&
              !_sourceBuffer!.updating!) {
            _mediaSource?.endOfStream();
            _isMediaSourceOpen = false;
            developer.log('MediaSource stream ended');
          } else {
            Future.delayed(Duration(milliseconds: 100), finalizeStream);
          }
        }

        finalizeStream();

        _combinedAudioBytes = [];
        _currentAudioMessageId = null;
        _firstChunkReceivedTime = null;
        _chunkSendStartTime = null;
        _chatState.setReceivingAudioChunks(false);
        _chatState.setLoading(false);
      }
    }
  }

  void _initializeMediaSource() {
    if (!kIsWeb) return;

    try {
      _mediaSource = html.MediaSource();
      _isMediaSourceOpen = false;
      _audioElement = html.AudioElement();
      _audioElement!.src = html.Url.createObjectUrl(_mediaSource!);
      _audioElement!.autoplay = true;
      html.document.body!.append(_audioElement!);

      _mediaSource!.addEventListener('sourceopen', (event) {
        _sourceBuffer = _mediaSource!.addSourceBuffer('audio/wav');
        _isMediaSourceOpen = true;
        developer.log('MediaSource opened and SourceBuffer initialized');
        _processAudioQueue();
      });

      _mediaSource!.addEventListener('sourceended', (event) {
        developer.log('MediaSource stream ended');
      });

      _audioElement!.onError.listen((_) {
        developer.log('Error playing MediaSource audio');
        _chatState.addChatMessage(
          ChatMessage(text: 'Error playing audio stream.', isUser: false),
        );
        _stopPlayback();
      });

      _audioElement!.onEnded.listen((_) {
        _chatState.stopPlayback();
        _stopPlayback();
      });
    } catch (e) {
      developer.log('Error initializing MediaSource: $e');
      _chatState.addChatMessage(
        ChatMessage(text: 'Error initializing audio stream.', isUser: false),
      );
      _stopPlayback();
    }
  }

  void _processAudioQueue() {
    if (!kIsWeb ||
        _audioChunkQueue.isEmpty ||
        _isProcessingQueue ||
        !_isMediaSourceOpen ||
        _sourceBuffer == null) {
      _isProcessingQueue = false;
      return;
    }

    _isProcessingQueue = true;
    _playAudioChunk(_audioChunkQueue.first);
  }

  void _playAudioChunk(Uint8List chunkBytes) {
    if (!kIsWeb) return;

    try {
      if (_mediaSource == null ||
          _sourceBuffer == null ||
          !_isMediaSourceOpen) {
        developer.log('MediaSource or SourceBuffer not initialized');
        _isProcessingQueue = false;
        return;
      }

      if (_sourceBuffer!.updating!) {
        _sourceBuffer!.addEventListener('updateend', (event) {
          _appendChunkToSourceBuffer(chunkBytes);
        }, true);
      } else {
        _appendChunkToSourceBuffer(chunkBytes);
      }
    } catch (e) {
      developer.log('Error in _playAudioChunk: $e');
      _chatState.addChatMessage(
        ChatMessage(text: 'Error playing audio stream.', isUser: false),
      );
      _isProcessingQueue = false;
    }
  }

  void _appendChunkToSourceBuffer(Uint8List chunkBytes) {
    try {
      developer.log(
        'Processing chunk. Queue size: ${_audioChunkQueue.length}, '
        'Total bytes accumulated: ${_combinedAudioBytes.length}',
      );

      _sourceBuffer!.appendBuffer(chunkBytes.buffer);
      developer.log(
        'Appended chunk to SourceBuffer, size: ${chunkBytes.length} bytes',
      );

      _audioChunkQueue.removeAt(0);
      _isProcessingQueue = false;
      _processAudioQueue();
    } catch (e) {
      developer.log('Error appending chunk to SourceBuffer: $e');
      _chatState.addChatMessage(
        ChatMessage(text: 'Error playing audio stream.', isUser: false),
      );
      _isProcessingQueue = false;
    }
  }

  void addAudioToChatMessageModel(Uint8List bytes) {
    _chatState.addChatMessage(
      ChatMessage(audioBytes: Uint8List.fromList(bytes), isUser: false),
    );
  }

  void _playBufferedAudio(bool isFinal) {
    if (!kIsWeb) return;

    try {
      final sortedKeys = _chunkedAudioMap.keys.toList()..sort();
      final combinedBase64 = sortedKeys.map((k) => _chunkedAudioMap[k]!).join();
      final audioBytes = base64Decode(combinedBase64);
      developer.log('Combined audio size: ${audioBytes.length} bytes');

      if (_audioElement == null) {
        _audioElement = html.AudioElement();
        _audioElement!.autoplay = true;
        html.document.body!.append(_audioElement!);
      }

      final blob = html.Blob([audioBytes], 'audio/wav');
      final url = html.Url.createObjectUrlFromBlob(blob);
      _audioElement!.src = url;
      _audioElement!.play().catchError((e) {
        developer.log('Error playing audio: $e');
        _chatState.addChatMessage(
          ChatMessage(text: 'Error playing audio.', isUser: false),
        );
      });

      if (_currentAudioMessageId != null) {
        _chatState.updateChatMessage(
          _currentAudioMessageId!,
          ChatMessage(
            audioBytes: audioBytes,
            isUser: false,
            isStreaming: !isFinal,
            id: _currentAudioMessageId,
          ),
        );
      }

      if (isFinal) {
        _chunkedAudioMap.clear();
        _currentAudioMessageId = null;
        _audioElement?.onEnded.listen((_) => _stopPlayback());
      }
    } catch (e) {
      developer.log('Error in _playBufferedAudio: $e');
      _chatState.addChatMessage(
        ChatMessage(text: 'Error playing audio stream.', isUser: false),
      );
      _stopPlayback();
    }
  }

  void playAudio(Uint8List audioBytes) {
    if (!kIsWeb) return;

    try {
      _stopPlayback();
      _audioElement = html.AudioElement();
      final blob = html.Blob([audioBytes], 'audio/wav');
      final url = html.Url.createObjectUrlFromBlob(blob);
      _audioElement!.src = url;
      _audioElement!.play().catchError((e) {
        developer.log('Error playing audio: $e');
        _chatState.addChatMessage(
          ChatMessage(text: 'Error playing audio.', isUser: false),
        );
      });
      _audioElement!.onEnded.listen((_) {
        _chatState.stopPlayback();
        _stopPlayback();
      });
      html.document.body!.append(_audioElement!);
    } catch (e) {
      developer.log('Error in playAudio: $e');
      _chatState.addChatMessage(
        ChatMessage(text: 'Error playing audio.', isUser: false),
      );
    }
  }

  void _stopPlayback() {
    if (_audioElement != null) {
      _audioElement!.pause();
      _audioElement!.remove();
      _audioElement = null;
    }
    if (_mediaSource != null) {
      if (_isMediaSourceOpen &&
          _sourceBuffer != null &&
          !_sourceBuffer!.updating!) {
        _mediaSource?.endOfStream();
      }
      _mediaSource = null;
      _sourceBuffer = null;
      _isMediaSourceOpen = false;
    }
    _audioChunkQueue.clear();
    _isProcessingQueue = false;
    _chatState.stopPlayback();
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        _chatState.setRecording(true);
        final micOpenTime = DateTime.now().millisecondsSinceEpoch;
        developer.log('Timelog - Mic opened at: $micOpenTime ms');
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
        final micCloseTime = DateTime.now().millisecondsSinceEpoch;
        developer.log('Timelog - Mic closed at: $micCloseTime ms');
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
    _stopPlayback();
    _chunkedAudioMap.clear();
    _currentAudioMessageId = null;
    _chunkSendStartTime = null;
  }
}
