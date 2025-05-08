import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat/chat_provider.dart';
import 'providers/chat/chat_state.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatState()),
        Provider(create: (context) => ChatProvider(context.read<ChatState>())),
      ],
      child: MaterialApp(
        title: 'FalconSpeak',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blueAccent,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          colorScheme: ColorScheme.dark(
            primary: Colors.blueAccent,
            secondary: Colors.grey[800]!,
            surface: Colors.grey[800]!,
          ),
        ),
        home: const ChatScreen(),
      ),
    );
  }
}
