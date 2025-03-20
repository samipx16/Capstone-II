import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_navbar.dart';
import '../challenge/tracking_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class _ChallengeScreenState extends State<ChallengeScreen> {
  int _currentIndex = 1; // Active tab index
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _filteredChallenges = [];
  bool _isSearching = false;

  final List<Map<String, dynamic>> challengeTypes = [
    {
      "title": "Daily Challenges",
      "description":
          "Complete your Daily Challenges to earn your daily points.",
      "icon": Icons.calendar_today,
      "route": "/dailyChallenges",
      "image": "assets/task-img.png",
    },
    {
      "title": "Weekly Challenges",
      "description": "Complete your Weekly Challenges to earn more points.",
      "icon": Icons.date_range,
      "route": "/weeklyChallenges",
      "image": "assets/task-img.png",
    },
    {
      "title": "One-time Challenges",
      "description":
          "Complete your One-time Challenge to earn a large amount of points.",
      "icon": Icons.verified,
      "route": "/oneTimeChallenges",
      "image": "assets/task-img.png",
    }
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChallenges);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChallenges() {
    String query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      // ✅ If search bar is empty, show default categories
      setState(() {
        _filteredChallenges = [];
        _isSearching = false;
      });
    } else {
      // ✅ Perform search if there is text
      _searchChallengesFromFirestore(query);
    }
  }

  /// Fetches challenges from Firestore where either `title` or `description` contains the query
  void _searchChallengesFromFirestore(String query) async {
    if (_auth.currentUser == null) return;
    String userId = _auth.currentUser!.uid;

    QuerySnapshot challengeSnapshot =
        await _firestore.collection('challenges').get();

    List<Map<String, dynamic>> searchResults = [];

    for (var doc in challengeSnapshot.docs) {
      Map<String, dynamic> challengeData = doc.data() as Map<String, dynamic>;
      String challengeId = doc.id;

      // Fetch the challenge's status from user_challenges
      DocumentSnapshot userChallengeSnapshot = await _firestore
          .collection('user_challenges')
          .doc("${userId}_$challengeId")
          .get();

      String challengeStatus = "not_started"; // Default status
      if (userChallengeSnapshot.exists) {
        Map<String, dynamic> userChallengeData =
            userChallengeSnapshot.data() as Map<String, dynamic>;
        challengeStatus = userChallengeData['status'] ?? "not_started";
      }

      if (challengeData["title"].toLowerCase().contains(query) ||
          challengeData["description"].toLowerCase().contains(query)) {
        searchResults.add({
          "id": challengeId,
          "title": challengeData["title"],
          "description": challengeData["description"],
          "icon": Icons.assignment, // Default icon
          "image": "assets/task-img.png",
          "status": challengeStatus, // ✅ Store challenge status
          "trackingMethod": challengeData["trackingMethod"] ?? "manual",
          "requiredProgress": challengeData.containsKey("requiredProgress")
              ? challengeData["requiredProgress"] as int
              : 1, // Default value
        });
      }
    }

    setState(() {
      _filteredChallenges = searchResults;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Challenges",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _filterChallenges(),
                decoration: InputDecoration(
                  hintText: "Search challenges...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13.0),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Challenge Display
            Expanded(
              child: _isSearching
                  ? (_filteredChallenges.isEmpty
                      ? const Center(
                          child: Text("No matching challenges found."))
                      : ListView.builder(
                          itemCount: _filteredChallenges.length,
                          itemBuilder: (context, index) {
                            final challenge = _filteredChallenges[index];
                            return _buildChallengeCategory(
                              title: challenge["title"],
                              description: challenge["description"],
                              icon: challenge["icon"],
                              imagePath: challenge["image"],
                              challengeID:
                                  challenge["id"], // ✅ Pass challenge ID
                              trackingMethod: challenge[
                                  "trackingMethod"], // ✅ Pass tracking method
                              requiredProgress: challenge[
                                  "requiredProgress"], // ✅ Pass required progress
                              status: challenge[
                                  "status"], // ✅ Pass challenge status
                            );
                          },
                        ))
                  : ListView.builder(
                      // ✅ Show Daily, Weekly, and One-time Challenges when NOT searching
                      itemCount: challengeTypes.length,
                      itemBuilder: (context, index) {
                        final category = challengeTypes[index];
                        return _buildChallengeCategory(
                          title: category["title"],
                          description: category["description"],
                          icon: category["icon"],
                          imagePath: category["image"],
                          challengeID: "", // Default empty
                          trackingMethod: "", // Default empty
                          requiredProgress: 1, // Default value
                          status: "not_started", // Default status
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Floating Action Button (QR Code Scanner)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.pushNamed(context, '/qr_scan');
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildChallengeCategory({
    required String title,
    required String description,
    required IconData icon,
    required String imagePath,
    required String challengeID,
    required String trackingMethod,
    required int requiredProgress,
    required String status, // ✅ Added challenge status
  }) {
    return GestureDetector(
      onTap: () {
        // ✅ Check if this is a category (Daily, Weekly, One-time)
        if (challengeID.isEmpty) {
          // Navigate to the respective challenge screen
          if (title.contains("Daily")) {
            Navigator.pushNamed(context, "/dailyChallenges");
          } else if (title.contains("Weekly")) {
            Navigator.pushNamed(context, "/weeklyChallenges");
          } else if (title.contains("One-time")) {
            Navigator.pushNamed(context, "/oneTimeChallenges");
          }
        } else {
          // ✅ Normal challenge behavior
          if (status == 'completed') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("This challenge is already completed."),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // ✅ Navigate to Tracking Methods Screen
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
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon on the left
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.green.shade100,
                child: Icon(icon, color: Colors.green, size: 35),
              ),
              const SizedBox(width: 16),

              // Expanded Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // ✅ Show "Completed" status for searched challenges
              challengeID.isNotEmpty && status == "completed"
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
                  : const SizedBox(), // Otherwise, show nothing
            ],
          ),
        ),
      ),
    );
  }
}
