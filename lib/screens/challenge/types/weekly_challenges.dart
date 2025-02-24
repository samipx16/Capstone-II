import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tracking_methods.dart';

class WeeklyChallengesScreen extends StatefulWidget {
  const WeeklyChallengesScreen({super.key});

  @override
  _WeeklyChallengesScreenState createState() => _WeeklyChallengesScreenState();
}

class _WeeklyChallengesScreenState extends State<WeeklyChallengesScreen> {
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
          title: const Text("Weekly Challenges"),
          backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('challenges')
            .where('frequency', isEqualTo: 'weekly')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No weekly challenges available."));
          }

          return ListView(
            children: snapshot.data!.docs.map((challenge) {
              var data = challenge.data() as Map<String, dynamic>;

              return StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('user_challenges')
                    .doc("${_user!.uid}_${challenge.id}")
                    .snapshots(),
                builder: (context, userChallengeSnapshot) {
                  bool isCompleted = false;
                  String status = "not_started";

                  if (userChallengeSnapshot.hasData &&
                      userChallengeSnapshot.data!.exists) {
                    var userChallengeData = userChallengeSnapshot.data!.data()
                        as Map<String, dynamic>;
                    status = userChallengeData['status'] ?? "not_started";

                    debugPrint(
                        "Challenge ${challenge.id} current status: $status");

                    isCompleted = status == 'completed';
                  }

                  return ListTile(
                    title: Text(data['title']),
                    subtitle: Text(data['description']),
                    trailing: isCompleted
                        ? const Text(
                            "✅ Completed",
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          )
                        : ElevatedButton(
                            onPressed: () => _startChallenge(
                              challenge.id,
                              data['trackingMethod'],
                              data['requiredProgress'] ?? 1,
                            ),
                            child: const Text("Start"),
                          ),
                  );
                },
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
      String challengeID, String? trackingMethod, int? requiredProgress) async {
    if (_user == null) {
      debugPrint("Error: User is not logged in.");
      return;
    }

    if (trackingMethod == null || requiredProgress == null) {
      debugPrint(
          "Error: Invalid challenge data (trackingMethod: $trackingMethod, requiredProgress: $requiredProgress)");
      requiredProgress = 1; // Default value
    }

    debugPrint("Starting challenge: $challengeID");

    // Set status to "in_progress" in Firestore when the challenge starts
    await _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_$challengeID")
        .set({
      'userID': _user!.uid,
      'challengeID': challengeID,
      'status': 'in_progress',
      'progress': 0, // Start with 0 progress
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingMethodsScreen(
          challengeID: challengeID,
          trackingMethod: trackingMethod!,
          requiredProgress: requiredProgress!,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
              index: 0, icon: Icons.home, label: "Home", route: '/dashboard'),
          _buildBottomNavItem(
              index: 1,
              icon: Icons.emoji_events,
              label: "Challenges",
              route: '/challenges'),
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
    );
  }

  Widget _buildBottomNavItem(
      {required int index,
      required IconData icon,
      required String label,
      required String route}) {
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
