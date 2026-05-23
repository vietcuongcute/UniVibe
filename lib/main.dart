import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';

void main() {
  runApp(const UniVibeApp());
}

class UniVibeApp extends StatelessWidget {
  const UniVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniVibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const WelcomeScreen(),
    );
  }
}
