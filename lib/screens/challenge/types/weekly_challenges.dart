import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tracking_methods.dart';
import './../../widgets/bottom_navbar.dart';

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
    _checkForWeeklyReset();
  }

  /// Checks if it's a new week and resets weekly challenges
  void _checkForWeeklyReset() async {
    if (_user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_user!.uid).get();
    Timestamp? lastReset = userDoc.exists ? userDoc['lastWeeklyReset'] : null;

    DateTime now = DateTime.now();
    DateTime lastResetDate = lastReset?.toDate() ?? DateTime(2000);

    // Check if today is Monday and last reset was in a previous week
    bool isNewWeek = now.weekday == DateTime.monday &&
        (now.difference(lastResetDate).inDays >= 7 ||
            lastResetDate.weekday != DateTime.monday);

    if (isNewWeek) {
      await _resetWeeklyChallenges();
    }
  }

  /// Resets all weekly challenges for the user
  Future<void> _resetWeeklyChallenges() async {
    if (_user == null) return;

    WriteBatch batch = _firestore.batch();

    QuerySnapshot userChallengesSnapshot = await _firestore
        .collection('user_challenges')
        .where('userID', isEqualTo: _user!.uid)
        .where('frequency', isEqualTo: 'weekly')
        .get();

    for (var doc in userChallengesSnapshot.docs) {
      batch.update(doc.reference, {
        'progress': 0,
        'status': 'not_started',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    batch.update(_firestore.collection('users').doc(_user!.uid), {
      'lastWeeklyReset': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "Weekly Challenges",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Rounded edges
                    ),
                    elevation: 4, // Adds shadow effect
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12), // Better spacing
                      title: Text(
                        data['title'],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        data['description'],
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      trailing: isCompleted
                          ? const Chip(
                              label: Text(
                                "Completed",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.green,
                            )
                          : ElevatedButton(
                              onPressed: () => _startChallenge(
                                challenge.id,
                                data['trackingMethod'],
                                data['requiredProgress'] ?? 1,
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              child: const Text("Start"),
                            ),
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
      bottomNavigationBar:
          BottomNavBar(currentIndex: _currentIndex, onTap: _onItemTapped),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
}
