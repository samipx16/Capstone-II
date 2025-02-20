import 'package:ecoeagle/screens/challenge/types/monthly_challenges.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'firebase_options.dart';
import 'screens/registration.dart';
import 'screens/dashboard.dart';
import 'screens/challenge/challenges.dart';
import 'screens/challenge/types/daily_challenges.dart';
import 'screens/challenge/types/weekly_challenges.dart';
import 'screens/challenge/types/one_time_challenges.dart';
import 'screens/challenge/types/monthly_challenges.dart';
import 'package:ecoeagle/screens/milestone.dart';

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
        '/dailyChallenges': (context) => const DailyChallengesScreen(),
        '/weeklyChallenges': (context) => const WeeklyChallengesScreen(),
        '/monthlyChallenges': (context) => const MonthlyChallengesScreen(),
        '/oneTimeChallenges': (context) => const OneTimeChallengesScreen(),
        '/milestones': (context) => MilestonesPage(),
      },
    );
  }
}
