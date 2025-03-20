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
                      trailing: Builder(
                        builder: (context) {
                          if (userChallengeSnapshot.hasData &&
                              userChallengeSnapshot.data!.exists) {
                            var userChallengeData = userChallengeSnapshot.data!
                                .data() as Map<String, dynamic>?;

                            if (userChallengeData != null &&
                                userChallengeData.containsKey('lastUpdated')) {
                              Timestamp lastUpdated =
                                  userChallengeData['lastUpdated'] as Timestamp;
                              DateTime lastUpdatedDate = lastUpdated.toDate();
                              DateTime now = DateTime.now();

                              //  If completed & lastUpdated is within 7 days, show "Completed"
                              if (status == 'completed' &&
                                  now.difference(lastUpdatedDate).inDays < 7) {
                                return const Chip(
                                  label: Text(
                                    "Completed",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                );
                              }
                            }
                          }

                          //  If challenge is not completed or it's a new week, show "Start" button
                          return ElevatedButton(
                            onPressed: () => _startChallenge(
                              challenge.id,
                              data['trackingMethod'],
                              data['requiredProgress'] ?? 1,
                            ),
                            child: const Text("Start"),
                          );
                        },
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
      requiredProgress = 1;
    }

    String userChallengeDocID = "${_user!.uid}_$challengeID";
    DocumentReference userChallengeRef =
        _firestore.collection('user_challenges').doc(userChallengeDocID);

    DocumentSnapshot userChallengeSnapshot = await userChallengeRef.get();

    int existingCompletedCount = 0;
    if (userChallengeSnapshot.exists) {
      var userChallengeData =
          userChallengeSnapshot.data() as Map<String, dynamic>;
      existingCompletedCount =
          userChallengeData['completedChallengesCount'] ?? 0;
    }

    await userChallengeRef.set({
      'challengeID': challengeID,
      'userID': _user!.uid,
      'status': 'not_started', // Ensure status resets
      'progress': 0,
      'requiredProgress': requiredProgress,
      'lastUpdated': Timestamp.now(),
      'completedChallengesCount':
          existingCompletedCount, // Keep previous completions
    }, SetOptions(merge: true));

    debugPrint("Weekly challenge reset while keeping completed count.");

    setState(() {});

    // Navigate to tracking methods screen
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
