import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SettingsPage.dart';
import 'about.dart';
import '../widgets/bottom_navbar.dart';
import 'UserSupport.dart';
import 'Leaderboard.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState(); // design Final
}

class _AccountPageState extends State<AccountPage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String _displayName = "User";
  String _photoURL = "";
  int _currentIndex = 3; // Set Account as active tab

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserPoints(); // Fetch user's total points
  }

  int _userPoints = 0; // Variable to store the total points

  Future<void> _fetchUserPoints() async {
    try {
      if (_user == null) return;

      String userId = _user!.uid;
      int totalPoints = 0;

      // Fetch user challenges
      QuerySnapshot userChallengesSnapshot = await _firestore
          .collection('user_challenges')
          .where('userID', isEqualTo: userId)
          .where('status',
              isEqualTo: 'completed') // Only count completed challenges
          .get();

      for (var challengeDoc in userChallengesSnapshot.docs) {
        Map<String, dynamic>? challengeData =
            challengeDoc.data() as Map<String, dynamic>?;

        if (challengeData == null) continue;

        String? challengeId = challengeData['challengeID'];
        int progress = (challengeData['progress'] as num?)?.toInt() ?? 0;

        if (challengeId != null) {
          // Fetch challenge points
          DocumentSnapshot challengeSnapshot =
              await _firestore.collection('challenges').doc(challengeId).get();

          Map<String, dynamic>? challengeInfo =
              challengeSnapshot.data() as Map<String, dynamic>?;

          if (challengeInfo != null) {
            int points = int.tryParse(challengeInfo['points'].toString()) ?? 0;
            totalPoints += (progress * points);
          }
        }
      }

      // Update state with total points
      setState(() {
        _userPoints = totalPoints;
      });
    } catch (e) {
      print("Error fetching user points: $e");
    }
  }

  void _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
      });

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _displayName = userDoc['name'] ?? "User";
          _photoURL = userDoc['photoURL'] ?? "";
        });
      }
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Account",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture with a Soft Glow Effect
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.green.shade700,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade200,
                      backgroundImage:
                          _photoURL.isNotEmpty ? NetworkImage(_photoURL) : null,
                      child: _photoURL.isEmpty
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _displayName,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "🏆 $_userPoints pts",
                    style: const TextStyle(fontSize: 20, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main Account Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 6,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildAnimatedButton(
                        Icons.campaign, "Challenges", '/challenges'),
                    const SizedBox(height: 10),
                    _buildAnimatedButton(
                        Icons.emoji_events, "Milestones", '/milestones'),
                    const SizedBox(height: 10),
                    _buildAnimatedButton(
                        Icons.leaderboard, "LeaderBoards", '/leaderboard'),
                    const SizedBox(height: 20),

                    // Settings Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSettingsOption("Settings", Icons.settings,
                              navigateToSettings: true),
                          _buildSettingsOption("About", Icons.info,
                              navigateToAbout: true),
                          _buildSettingsOption(
                              "User Support", Icons.support_agent,
                              navigateToSupport: true),
                          _buildSettingsOption("Logout", Icons.logout,
                              isLogout: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // QR Code Floating Action Button with Hover Animation
      floatingActionButton: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 1.0, end: 1.1),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () {
                Navigator.pushNamed(context, '/qr_scan');
              },
              shape: const CircleBorder(),
              child: const Icon(Icons.qr_code, color: Colors.white),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Animated Button with Scaling Effect
  Widget _buildAnimatedButton(IconData icon, String label, String route) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 1.0, end: 1.05),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              Navigator.pushNamed(context, route);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsOption(String label, IconData icon,
      {bool isLogout = false,
      bool navigateToSettings = false,
      bool navigateToAbout = false,
      bool navigateToSupport = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.green.shade800),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      onTap: isLogout
          ? _logout
          : navigateToSettings
              ? () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SettingsPage()));
                }
              : navigateToAbout
                  ? () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => AboutPage()));
                    }
                  : navigateToSupport
                      ? () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserSupportPage()));
                        }
                      : () {},
    );
  }
}
