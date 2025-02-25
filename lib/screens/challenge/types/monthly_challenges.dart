import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './../../widgets/bottom_navbar.dart';

class MonthlyChallengesScreen extends StatefulWidget {
  const MonthlyChallengesScreen({super.key});

  @override
  _MonthlyChallengesScreenState createState() =>
      _MonthlyChallengesScreenState();
}

class _MonthlyChallengesScreenState extends State<MonthlyChallengesScreen> {
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
          title: const Text("Monthly Challenges"),
          backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('challenges')
            .where('frequency', isEqualTo: 'monthly')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No monthly challenges available."));
          }

          return ListView(
            children: snapshot.data!.docs.map((challenge) {
              var data = challenge.data() as Map<String, dynamic>;
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.green),
                  title: Text(data['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['description']),
                  trailing: ElevatedButton(
                    onPressed: () => _startChallenge(challenge.id),
                    child: const Text("Start"),
                  ),
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
      bottomNavigationBar:
          BottomNavBar(currentIndex: _currentIndex, onTap: _onItemTapped),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _startChallenge(String challengeID) async {
    if (_user == null) return;

    await _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_$challengeID")
        .set({
      'userID': _user!.uid,
      'challengeID': challengeID,
      'status': 'in_progress',
      'progress': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
      'frequency': 'monthly',
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Monthly Challenge Started!")));
  }
}
