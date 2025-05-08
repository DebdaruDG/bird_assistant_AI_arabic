import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isRecording;

  const MicButton({super.key, required this.onTap, required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white),
    );
  }
}
