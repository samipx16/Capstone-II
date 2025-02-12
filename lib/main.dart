import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'screens/registration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EcoEagleApp());
}

class EcoEagleApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // Show loading spinner while Firebase initializes
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Show error message if Firebase fails to initialize
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text("Firebase Initialization Error!")),
            ),
          );
        }

        // Once Firebase is initialized, show the LoginScreen
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RegisterScreen(),
        );
      },
    );
  }
}
