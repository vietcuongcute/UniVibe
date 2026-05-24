import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const UniVibeApp());
}

class UniVibeApp extends StatelessWidget {
  const UniVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniVibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7B61FF),
        scaffoldBackgroundColor: const Color(0xFFF7F3FF),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
