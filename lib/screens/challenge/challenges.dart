import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_navbar.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

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
      setState(() {
        _filteredChallenges = [];
        _isSearching = false;
      });
    } else {
      _searchChallengesFromFirestore(query);
    }
  }

  /// Fetches challenges from Firestore where either `title` or `description` contains the query
  void _searchChallengesFromFirestore(String query) async {
    QuerySnapshot querySnapshot =
        await _firestore.collection('challenges').get();

    List<Map<String, dynamic>> searchResults = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((challenge) {
      String title = challenge['title'].toString().toLowerCase();
      String description = challenge['description'].toString().toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();

    setState(() {
      _filteredChallenges = searchResults.map((challenge) {
        return {
          "title": challenge["title"],
          "description": challenge["description"],
          "icon": Icons.assignment, // Default icon
          "route": "/challengeDetails", // Example route
          "image": "assets/task-img.png",
        };
      }).toList();
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
                              route: challenge["route"],
                              imagePath: challenge["image"],
                              taskCount:
                                  0, // Firestore data may not have task count
                            );
                          },
                        ))
                  : ListView.builder(
                      itemCount: challengeTypes.length,
                      itemBuilder: (context, index) {
                        final category = challengeTypes[index];
                        return _buildChallengeCategory(
                          title: category["title"],
                          description: category["description"],
                          icon: category["icon"],
                          route: category["route"],
                          imagePath: category["image"],
                          taskCount: 0, // Default value
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
    required String route,
    required String imagePath,
    required int taskCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
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

              // Image on the right
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
