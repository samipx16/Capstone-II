import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeLogScreen extends StatefulWidget {
  const ChallengeLogScreen({super.key});

  @override
  _ChallengeLogScreenState createState() => _ChallengeLogScreenState();
}

class _ChallengeLogScreenState extends State<ChallengeLogScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _resetUserChallenges();
  }

  Future<void> _resetUserChallenges() async {
    if (_user == null) return;
    QuerySnapshot userChallenges = await _firestore
        .collection('user_challenges')
        .where('userID', isEqualTo: _user!.uid)
        .get();

    for (var doc in userChallenges.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
      String frequency = data['frequency'];

      if (_shouldResetChallenge(frequency, lastUpdated)) {
        await _firestore.collection('user_challenges').doc(doc.id).update({
          'status': 'in_progress',
          'progress': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  bool _shouldResetChallenge(String frequency, DateTime lastUpdated) {
    DateTime now = DateTime.now();
    switch (frequency) {
      case "daily":
        return now.difference(lastUpdated).inDays >= 1;
      case "weekly":
        return now.difference(lastUpdated).inDays >= 7;
      case "monthly":
        return now.month != lastUpdated.month;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Challenge Log"), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('user_challenges')
            .where('userID', isEqualTo: _user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No challenges logged."));
          }

          return ListView(
            children: snapshot.data!.docs.map((challenge) {
              var data = challenge.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['challengeID']),
                subtitle: Text("Status: ${data['status']}"),
                trailing: data['status'] == "completed"
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        onPressed: () => _completeChallenge(challenge.id),
                        child: const Text("Complete"),
                      ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _completeChallenge(String challengeID) async {
    if (_user == null) return;

    await _firestore.collection('user_challenges').doc(challengeID).update({
      'status': 'completed',
      'completionDate': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Challenge Completed!")));
  }
}
