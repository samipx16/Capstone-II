import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tracking_methods.dart';
import './../../widgets/bottom_navbar.dart';

class DailyChallengesScreen extends StatefulWidget {
  const DailyChallengesScreen({super.key});

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
    _checkForDailyReset();
  }

  /// Checks if it's a new day and resets daily challenges
  void _checkForDailyReset() async {
    if (_user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_user!.uid).get();
    Timestamp? lastReset = userDoc.exists ? userDoc['lastReset'] : null;

    DateTime now = DateTime.now();
    DateTime lastResetDate = lastReset?.toDate() ?? DateTime(2000);

    bool isNewDay = now.year > lastResetDate.year ||
        now.month > lastResetDate.month ||
        now.day > lastResetDate.day;

    if (isNewDay) {
      await _resetDailyChallenges();
    }
  }

  /// Resets all daily challenges for the user
  Future<void> _resetDailyChallenges() async {
    if (_user == null) return;

    WriteBatch batch = _firestore.batch();

    QuerySnapshot userChallengesSnapshot = await _firestore
        .collection('user_challenges')
        .where('userID', isEqualTo: _user!.uid)
        .where('frequency', isEqualTo: 'daily')
        .get();

    for (var doc in userChallengesSnapshot.docs) {
      batch.update(doc.reference, {
        'progress': 0,
        'status': 'not_started',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    batch.update(_firestore.collection('users').doc(_user!.uid), {
      'lastReset': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            "Daily Challenges",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green),
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
      String challengeID, String? trackingMethod, int? requiredProgress) {
    if (_user == null) {
      debugPrint("Error: User is not logged in.");
      return;
    }

    if (trackingMethod == null || requiredProgress == null) {
      debugPrint(
          "Error: Invalid challenge data (trackingMethod: $trackingMethod, requiredProgress: $requiredProgress)");
      requiredProgress = 1;
    }

    debugPrint(
        "Navigating to TrackingMethodsScreen with Challenge ID: $challengeID");

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
