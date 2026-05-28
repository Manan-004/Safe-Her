import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safe_her/screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ Firebase initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        "/splash": (context) => const SplashScreen(),
        "/login": (context) => const LoginScreen(),
        "/mainScreen": (context) => const MainScreen(),
      },
    );
  }
}
