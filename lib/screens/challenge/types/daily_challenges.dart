import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tracking_methods.dart';

class DailyChallengesScreen extends StatefulWidget {
  const DailyChallengesScreen({Key? key}) : super(key: key);

  @override
  _DailyChallengesScreenState createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Daily Challenges"), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('challenges')
            .where('frequency', isEqualTo: 'daily')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No daily challenges available."));
          }

          return ListView(
            children: snapshot.data!.docs.map((challenge) {
              var data = challenge.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title']),
                subtitle: Text(data['description']),
                trailing: ElevatedButton(
                  onPressed: () => _startChallenge(challenge.id,
                      data['trackingMethod'], data['requiredProgress']),
                  child: const Text("Start"),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.pushNamed(context, '/qr_scan');
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  void _startChallenge(
      String challengeID, String trackingMethod, int requiredProgress) async {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingMethodsScreen(
          challengeID: challengeID,
          trackingMethod: trackingMethod,
          requiredProgress: requiredProgress,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
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
                  _buildBottomNavItem(
                      index: 0,
                      icon: Icons.home,
                      label: "Home",
                      route: '/dashboard'),
                  _buildBottomNavItem(
                      index: 1,
                      icon: Icons.emoji_events,
                      label: "Challenges",
                      route: '/challenges'),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavItem(
                      index: 2,
                      icon: Icons.star,
                      label: "Milestones",
                      route: '/milestones'),
                  _buildBottomNavItem(
                      index: 3,
                      icon: Icons.account_circle,
                      label: "Account",
                      route: '/account'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required String route,
  }) {
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
          Text(label,
              style: TextStyle(
                  color: isActive ? Colors.green : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
