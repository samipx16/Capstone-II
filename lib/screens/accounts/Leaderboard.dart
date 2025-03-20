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
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .orderBy('lifetimePoints', descending: true)
          .limit(50) // Limit to top 50 users for performance
          .get();

      List<Map<String, dynamic>> sortedLeaderboard =
          usersSnapshot.docs.map((doc) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        return {
          'userId': doc.id,
          'name': userData['name'] ?? 'Unknown',
          'photoURL': userData['photoURL'] ?? '',
          'score': userData['lifetimePoints'] ?? 0,
        };
      }).toList();

      setState(() {
        _leaderboard = sortedLeaderboard;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching leaderboard data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "🏆 Leaderboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: TextField(
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Search Player",
                          hintStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.black54),
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
                              !user['name']
                                  .toLowerCase()
                                  .contains(_searchQuery)) {
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
        _buildPodiumSpot(_leaderboard[0], 1, Colors.amber, 80),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPodiumSpot(_leaderboard[1], 2, Colors.grey, 60),
            const SizedBox(width: 40),
            _buildPodiumSpot(_leaderboard[2], 3, Colors.brown, 60),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumSpot(
      Map<String, dynamic> user, int rank, Color color, double size) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (rank == 1)
                  ? Colors.amber
                  : (rank == 2)
                      ? Colors.grey
                      : Colors.brown,
              width: 6,
            ),
          ),
          child: CircleAvatar(
            radius: size - 16,
            backgroundImage: user['photoURL'].isNotEmpty
                ? NetworkImage(user['photoURL'])
                : null,
            child: user['photoURL'].isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
            backgroundColor: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "${user['score']} Pts",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
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
        backgroundImage:
            user['photoURL'].isNotEmpty ? NetworkImage(user['photoURL']) : null,
        child: user['photoURL'].isEmpty
            ? const Icon(Icons.person, color: Colors.black)
            : null,
        backgroundColor: Colors.green.shade900,
      ),
      title: Text("${index + 1}. ${user['name']}",
          style: const TextStyle(color: Colors.black)),
      trailing: Text("${user['score']} Pts",
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
