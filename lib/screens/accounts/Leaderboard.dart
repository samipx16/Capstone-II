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
  String _searchQuery = "";

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

      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          String name = userData['name'] ?? 'Unknown';
          String photoUrl = userData['photoURL'] ?? '';
          userNames[userId] = name;
          userPhotos[userId] = photoUrl;
          userScores[userId] = 0;
        }
      }

      QuerySnapshot userChallengesSnapshot =
      await _firestore.collection('user_challenges').get();

      for (var challengeDoc in userChallengesSnapshot.docs) {
        Map<String, dynamic>? challengeData =
        challengeDoc.data() as Map<String, dynamic>?;
        if (challengeData == null) continue;

        String? userId = challengeData['userID'];
        String? challengeId = challengeData['challengeID'];
        int progress = (challengeData['progress'] as num?)?.toInt() ?? 0;
        String status = challengeData['status'] ?? '';

        if (userId == null || challengeId == null) continue;

        if (status == 'completed' && userScores.containsKey(userId)) {
          DocumentSnapshot challengeSnapshot =
          await _firestore.collection('challenges').doc(challengeId).get();
          Map<String, dynamic>? challengeInfo =
          challengeSnapshot.data() as Map<String, dynamic>?;

          if (challengeInfo != null) {
            int points = int.tryParse(challengeInfo['points'].toString()) ?? 0;
            userScores[userId] = (userScores[userId] ?? 0) + (progress * points);
          }
        }
      }

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
      backgroundColor: Colors.white, // Light background
      appBar: AppBar(
        title: const Text("🏆 Leaderboard "),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
          ? const Center(
        child: Text(
          "No leaderboard data available",
          style: TextStyle(color: Colors.black87),
        ),
      )
          : Column(
        children: [
          const SizedBox(height: 10),
          _buildPodium(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Search Player",
                hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.grey.shade200, // Light background for search bar
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none, // Remove border outline
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final user = _leaderboard[index];
                if (_searchQuery.isNotEmpty &&
                    !user['name'].toLowerCase().contains(_searchQuery)) {
                  return const SizedBox();
                }
                return _buildLeaderboardTile(user, index);
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPodium() {
    if (_leaderboard.length < 3) return const SizedBox();

    return Column(
      children: [
        // First Place at the top
        _buildPodiumSpot(_leaderboard[0], 1, Colors.amber, 80),

        // Second and Third Place below in a row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPodiumSpot(_leaderboard[1], 2, Colors.grey, 60),
            const SizedBox(width: 40), // Space between 2nd and 3rd
            _buildPodiumSpot(_leaderboard[2], 3, Colors.brown, 60),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumSpot(Map<String, dynamic> user, int rank, Color color, double size) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4), // Creates the ring effect
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (rank == 1) ? Colors.amber : (rank == 2) ? Colors.grey : Colors.brown, // Gold, Silver, Bronze
              width: 6, // Thickness of the ring
            ),
          ),
          child: CircleAvatar(
            radius: size - 16, // Reduce profile pic size slightly
            backgroundImage: user['photoURL'].isNotEmpty ? NetworkImage(user['photoURL']) : null,
            child: user['photoURL'].isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 30) // Adjust icon size
                : null,
            backgroundColor: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "${user['score']} Pts",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          user['name'],
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }


  Widget _buildLeaderboardTile(Map<String, dynamic> user, int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['photoURL'].isNotEmpty ? NetworkImage(user['photoURL']) : null,
        child: user['photoURL'].isEmpty ? const Icon(Icons.person, color: Colors.black) : null,
        backgroundColor: Colors.green.shade900,
      ),
      title: Text("${index + 1}. ${user['name']}", style: const TextStyle(color: Colors.black)),
      trailing: Text("${user['score']} Pts", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
