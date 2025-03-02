import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SettingsPage.dart'; // Import the SettingsPage
import 'about.dart';
import '../widgets/bottom_navbar.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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
              // Profile Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade400],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 6,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade200,
                      backgroundImage:
                          _photoURL.isNotEmpty ? NetworkImage(_photoURL) : null,
                      child: _photoURL.isEmpty
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _displayName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    const Text("🏆 65 pts",
                        style: TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Unified Main Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 6,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildButton(Icons.campaign, "Challenges", '/challenges',
                        Colors.green.shade700),
                    const SizedBox(height: 10),
                    _buildButton(Icons.emoji_events, "Milestones",
                        '/milestones', Colors.green.shade700),
                    const SizedBox(height: 20),

                    // Sub-container for Settings, About, Privacy, Logout
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Ensures content aligns to center
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Centers items within column
                        children: [
                          _buildSettingsOption("Settings",
                              navigateToSettings: true),
                          _buildSettingsOption("About", navigateToAbout: true),
                          _buildSettingsOption("Privacy Policy"),
                          _buildSettingsOption("Logout", isLogout: true),
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

      // QR Code Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.pushNamed(context, '/qr_scan');
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
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

  Widget _buildButton(IconData icon, String label, String route, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(double.infinity, 45),
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
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(String label,
      {bool isLogout = false,
      bool navigateToSettings = false,
      bool navigateToAbout = false}) {
    return Center(
      // Ensures horizontal centering
      child: ListTile(
        title: Text(
          label,
          textAlign:
              TextAlign.center, // Ensures text is centered inside ListTile
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        onTap: isLogout
            ? _logout
            : navigateToSettings
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    ).then((_) => _fetchUserData()); // Refresh data on return
                  }
                : navigateToAbout
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutPage()),
                        ).then(
                            (_) => _fetchUserData()); // Refresh data on return
                      }
                    : () {},
      ),
    );
  }
}
