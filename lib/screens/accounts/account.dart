import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
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
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
              child: _user?.photoURL == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
            ),
            const SizedBox(height: 10),
            Text(
              _user?.displayName ?? "User",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text("🏆 65 pts", style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 20),

            // Challenges & Milestones Buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildButton(Icons.campaign, "Challenges", '/challenges', Colors.green),
                  _buildButton(Icons.emoji_events, "Milestones", '/milestones', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings Options
            _buildSettingsOption("Settings"),
            _buildSettingsOption("About"),
            _buildSettingsOption("Privacy Policy"),
            _buildSettingsOption("Logout", isLogout: true),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomNavItem(0, Icons.home, "Home", '/dashboard'),
                      _buildBottomNavItem(1, Icons.emoji_events, "Challenges", '/challenges'),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomNavItem(2, Icons.star, "Milestones", '/milestones'),
                      _buildBottomNavItem(3, Icons.account_circle, "Account", ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, String route, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(String label, {bool isLogout = false}) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: isLogout ? Colors.red : Colors.black54,
        ),
      ),
      onTap: isLogout ? _logout : () {},
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label, String route) {
    bool isActive = _currentIndex == index;
    return MaterialButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
        if (route.isNotEmpty) {
          Navigator.pushNamed(context, route);
        }
      },
      minWidth: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.green : Colors.grey),
          Text(label, style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
