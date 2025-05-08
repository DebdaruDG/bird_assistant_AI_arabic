import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../models/chat_model.dart';

class ChatState with ChangeNotifier {
  bool _isRecording = false;
  bool _isLoading = false;
  bool _isReceivingAudioChunks = false;
  bool _isPlaying = false;
  final AudioPlayer _sharedPlayer = AudioPlayer();
  final List<ChatMessage> _chats = [];
  Uint8List? _currentPlayingAudio;
  Duration? _currentPosition;
  final Map<Uint8List, Duration> _pausedPositions = {};

  // Getters
  List<ChatMessage> get chats => _chats;
  AudioPlayer get sharedPlayer => _sharedPlayer;
  bool get isRecording => _isRecording;
  bool get isLoading => _isLoading;
  bool get isReceivingAudioChunks => _isReceivingAudioChunks;
  bool get isPlaying => _isPlaying;

  ChatState() {
    _sharedPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _currentPlayingAudio = null;
      notifyListeners();
    });

    _sharedPlayer.onPositionChanged.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });
  }

  // State setters
  void setRecording(bool value) {
    _isRecording = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setReceivingAudioChunks(bool value) {
    _isReceivingAudioChunks = value;
    notifyListeners();
  }

  void addChatMessage(ChatMessage message) {
    _chats.add(message);
    notifyListeners();
  }

  void removeLoadingMessages() {
    _chats.removeWhere((m) => m.isLoading);
    notifyListeners();
  }

  Future<void> togglePlayPause(Uint8List audioBytes) async {
    if (_currentPlayingAudio != null && _currentPlayingAudio != audioBytes) {
      await _sharedPlayer.stop();
      _pausedPositions[_currentPlayingAudio!] =
          _currentPosition ?? Duration.zero;
    }

    if (_isPlaying && _currentPlayingAudio == audioBytes) {
      await _sharedPlayer.pause();
      _pausedPositions[audioBytes] = _currentPosition ?? Duration.zero;
      _isPlaying = false;
    } else {
      if (_currentPlayingAudio != audioBytes) {
        await _sharedPlayer.setSource(BytesSource(audioBytes));
        await _sharedPlayer.resume();
        _currentPlayingAudio = audioBytes;
        _isPlaying = true;
      } else {
        await _sharedPlayer.resume();
        _isPlaying = true;
      }

      final resumePosition = _pausedPositions[audioBytes];
      if (resumePosition != null) {
        await _sharedPlayer.seek(resumePosition);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sharedPlayer.dispose();
    super.dispose();
  }
}
