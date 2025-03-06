import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    try {
      Map<String, int> userScores = {};
      Map<String, String> userNames = {};
      Map<String, String> userPhotos = {};

      // Fetch all users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          String name = userData['name'] ?? 'Unknown';
          String photoUrl = userData['photoURL'] ?? '';
          userNames[userId] = name;
          userPhotos[userId] = photoUrl;
          userScores[userId] = 0; // Initialize score
        }
      }

      // Fetch all user challenges
      QuerySnapshot userChallengesSnapshot =
      await _firestore.collection('user_challenges').get();

      for (var challengeDoc in userChallengesSnapshot.docs) {
        Map<String, dynamic>? challengeData = challengeDoc.data() as Map<String, dynamic>?;

        if (challengeData == null) continue;

        String? userId = challengeData['userID'];
        String? challengeId = challengeData['challengeID'];
        int progress = (challengeData['progress'] as num?)?.toInt() ?? 0;
        String status = challengeData['status'] ?? '';

        if (userId == null || challengeId == null) continue;

        if (status == 'completed' && userScores.containsKey(userId)) {
          // Fetch challenge points
          DocumentSnapshot challengeSnapshot =
          await _firestore.collection('challenges').doc(challengeId).get();

          Map<String, dynamic>? challengeInfo = challengeSnapshot.data() as Map<String, dynamic>?;

          if (challengeInfo != null) {
            int points = int.tryParse(challengeInfo['points'].toString()) ?? 0;
            userScores[userId] = (userScores[userId] ?? 0) + (progress * points);
          }
        }
      }

      // Convert map to list and sort
      List<Map<String, dynamic>> sortedLeaderboard = userScores.entries
          .map((entry) => {
        'userId': entry.key,
        'name': userNames[entry.key] ?? "Unknown",
        'photoURL': userPhotos[entry.key] ?? "",
        'score': entry.value ?? 0,
      })
          .toList();

      sortedLeaderboard.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

      setState(() {
        _leaderboard = sortedLeaderboard;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching leaderboard data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏆 Leaderboard 🏆"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
          ? const Center(child: Text("No leaderboard data available"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final user = _leaderboard[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: user['photoURL'].isNotEmpty
                    ? NetworkImage(user['photoURL'])
                    : null,
                child: user['photoURL'].isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
                backgroundColor: Colors.green.shade200,
              ),
              title: Text(
                "${index + 1}. ${user['name']}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                "${user['score']} pts",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
          );
        },
      ),
    );
  }
}
