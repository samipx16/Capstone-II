import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'firebase_options.dart';
import 'screens/registration.dart';
import 'screens/dashboard.dart';
import 'screens/challenges.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Ensure Firebase is initialized once
  runApp(const EcoEagleApp());
}

class EcoEagleApp extends StatelessWidget {
  const EcoEagleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/challenges': (context) => ChallengeScreen(),
      },
    );
  }
}
