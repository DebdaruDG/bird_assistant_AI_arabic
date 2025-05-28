import 'package:flutter/foundation.dart';
import '../../models/chat_model.dart';

class ChatState extends ChangeNotifier {
  final List<ChatMessage> _chats = [];
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isReceivingAudioChunks = false;
  int _sendEndTime = 0;
  int _micOpenTime = 0;
  bool _isPlaying = false; // Track playback state
  String? _currentPlayingMessageId; // Track currently playing message

  List<ChatMessage> get chats => _chats;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  bool get isReceivingAudioChunks => _isReceivingAudioChunks;
  int getSendEndTime() => _sendEndTime;
  int getMicOpenTime() => _micOpenTime;
  bool get isPlaying => _isPlaying;

  void addChatMessage(ChatMessage message) {
    _chats.add(message);
    notifyListeners();
  }

  void updateChatMessage(String id, ChatMessage updatedMessage) {
    final index = _chats.indexWhere((msg) => msg.id == id);
    if (index != -1) {
      _chats[index] = updatedMessage;
      notifyListeners();
    }
  }

  void updateLastChatMessage(ChatMessage updatedMessage) {
    if (_chats.isNotEmpty) {
      _chats[_chats.length - 1] = updatedMessage;
      notifyListeners();
    }
  }

  void removeLoadingMessages() {
    _chats.removeWhere((message) => message.isLoading);
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setRecording(bool value) {
    _isRecording = value;
    notifyListeners();
  }

  void setReceivingAudioChunks(bool value) {
    _isReceivingAudioChunks = value;
    notifyListeners();
  }

  void setSendEndTime(int time) {
    _sendEndTime = time;
  }

  void setMicOpenTime(int time) {
    _micOpenTime = time;
  }

  void togglePlayPause(
    Uint8List audioBytes,
    String messageId,
    Function(Uint8List) playAudio,
  ) {
    if (_currentPlayingMessageId == messageId && _isPlaying) {
      _isPlaying = false;
      _currentPlayingMessageId = null;
      notifyListeners();
    } else {
      _isPlaying = true;
      _currentPlayingMessageId = messageId;
      playAudio(audioBytes);
      notifyListeners();
    }
  }

  void stopPlayback() {
    _isPlaying = false;
    _currentPlayingMessageId = null;
    notifyListeners();
  }
}
