import 'package:flutter/material.dart';
import 'screens/login.dart';
//import 'screens/registration.dart';

void main() {
  runApp(EcoEagleApp());
}

class EcoEagleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Set initial screen
      //home: RegisterScreen(),
    );
  }
}
