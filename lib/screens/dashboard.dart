import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecoeagle/screens/map_screen.dart';
import './widgets/bottom_navbar.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Index for the active bottom nav item (0: Home, 1: Challenges, 2: Milestones, 3: Account)
  int _currentIndex = 0;

  // Simulated user streak data for the current week (Monday - Sunday)
  final List<bool?> weeklyContributions = [
    true,
    true,
    false,
    true,
    true,
    null,
    null,
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  int _userPoints = 0;
  int _userRank = 0;
  int _userRecycled = 0;

  bool _isLoading = true;
  List<Map<String, dynamic>> _topThree = [];
  // Get the current weekday index (0 = Monday, 6 = Sunday)
  final int currentDayIndex =
      DateTime.now().weekday - 1; // Adjust index (Monday = 0)
  @override
  void initState() {
    super.initState();
    _fetchTopThree();
    _user = _auth.currentUser;
    _fetchUserPoints();
    _fetchUserRank();
    _fetchWeeklyChallenges();
  }

  Future<void> _fetchUserPoints() async {
    try {
      _user = _auth.currentUser;
      if (_user == null) return;

      String userId = _user!.uid;

      // ✅ Fetch lifetime points directly from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        int lifetimePoints = userData['lifetimePoints'] ?? 0;

        // ✅ Update state with fetched lifetime points
        setState(() {
          _userPoints = lifetimePoints;
        });

        debugPrint("✅ Lifetime points fetched: $lifetimePoints");
      } else {
        debugPrint("❌ User document does not exist");
      }
    } catch (e) {
      debugPrint("❌ Error fetching lifetime points: $e");
    }
  }

  /// Fetch user rank from the leaderboard
  Future<void> _fetchRecycle() async {
    try {
      if (_user == null) return;

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      Map<String, int> userScores = {};

      // Fetch user challenge progress
      QuerySnapshot userChallengesSnapshot =
          await firestore.collection('user_challenges').get();
      int count = 0;
      for (var challengeDoc in userChallengesSnapshot.docs) {
        Map<String, dynamic>? challengeData =
            challengeDoc.data() as Map<String, dynamic>?;

        if (challengeData == null) continue;

        String? userId = challengeData['userID'];
        String? challengeId = challengeData['challengeID'];
        int progress = (challengeData['progress'] as num?)?.toInt() ?? 0;
        String status = challengeData['status'] ?? '';

        if (userId == null || challengeId == null) continue;

        if (status == 'completed' && userId == _user!.uid) {
          count++;
        }
      }
      setState(() {
        _userRecycled = count;
      });
    } catch (e) {
      print("Error fetching user rank: $e");
    }
  }

  /// Fetch user rank from the leaderboard
  Future<void> _fetchUserRank() async {
    try {
      if (_user == null) return;

      String userId = _user!.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // ✅ Fetch all users ordered by `lifetimePoints`
      QuerySnapshot usersSnapshot = await firestore
          .collection('users')
          .orderBy('lifetimePoints', descending: true)
          .get();

      int rank = 1; // Start ranking from 1
      bool foundUser = false;

      for (var doc in usersSnapshot.docs) {
        if (doc.id == userId) {
          foundUser = true;
          break; // Stop when we find the user's rank
        }
        rank++;
      }

      if (foundUser) {
        setState(() {
          _userRank = rank;
        });
        debugPrint("✅ User rank updated: $rank");
      } else {
        debugPrint("❌ User not found in leaderboard");
      }
    } catch (e) {
      debugPrint("❌ Error fetching user rank: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTopThree() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // ✅ Fetch the top 3 users based on `lifetimePoints`
      QuerySnapshot usersSnapshot = await firestore
          .collection('users')
          .orderBy('lifetimePoints', descending: true)
          .limit(3)
          .get();

      List<Map<String, dynamic>> topThree = usersSnapshot.docs.map((doc) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        return {
          'name': userData['name'] ?? 'Unknown',
          'photoURL': userData['photoURL'] ?? '',
          'score': userData['lifetimePoints'] ?? 0,
        };
      }).toList();

      debugPrint("✅ Top 3 users fetched successfully");
      return topThree;
    } catch (e) {
      debugPrint("❌ Error fetching top three leaderboard: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF03AC52),
              Color(0xFF00853E),
            ],
            stops: [0.11, 0.68],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Good Morning, Sustainability Hero!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    value: (_userPoints / 100)
                                        .clamp(0.0, 1.0), // Normalized progress
                                    backgroundColor: Colors.grey[300],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(
                                                0xFF2E7D32)), // Green progress
                                    strokeWidth: 6,
                                  ),
                                ),
                                const Icon(Icons.star,
                                    color: Color(0xFFFAE500), size: 30),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("$_userPoints pts",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Color(0xFFFAE500), size: 30),
                            const SizedBox(height: 4),
                            Text(
                              "#$_userRank",
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const Text(
                              "Your Rank",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.recycling,
                                color: Color(0xFFFAE500), size: 30),
                            SizedBox(height: 4),
                            Text("$_userRecycled",
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            Text("Recycled",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Row for Map and Leaderboard Widgets
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 160,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MapScreen()),
                          );
                        },
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.grey, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                "Map",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Find the closest\nRecycle Bin",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 160,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SingleChildScrollView(
                            // ✅ Added to prevent overflow
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchTopThree(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError ||
                                    snapshot.data == null ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text(
                                          "No leaderboard data available"));
                                }

                                List<Map<String, dynamic>> topThree =
                                    snapshot.data!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Leaderboard",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.star, color: Colors.amber),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // ✅ Dynamic leaderboard entries using Firestore data
                                    _leaderboardEntry(
                                        "1. ${topThree[0]['name']}",
                                        topThree[0]['score'],
                                        Colors.amber),
                                    if (topThree.length > 1)
                                      _leaderboardEntry(
                                          "2. ${topThree[1]['name']}",
                                          topThree[1]['score'],
                                          Colors.grey),
                                    if (topThree.length > 2)
                                      _leaderboardEntry(
                                          "3. ${topThree[2]['name']}",
                                          topThree[2]['score'],
                                          Colors.brown),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        "This Week - ${_getCurrentWeekDateRange()}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (index) {
                          return Column(
                            children: [
                              _getStreakIcon(
                                  index), // Fetch icon based on streak data
                              const SizedBox(height: 4),
                              Text(_getWeekdayLabel(index)),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // QR Code Button as a FAB that is center-docked
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {},
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // BottomAppBar wrapped with SafeArea and MediaQuery.removePadding to fix overflow
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

  Future<void> _fetchWeeklyChallenges() async {
    try {
      if (_user == null) return;

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DateTime now = DateTime.now();
      DateTime startOfWeek =
          now.subtract(Duration(days: now.weekday - 1)); // Monday
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sunday

      // Fetch all challenges for the user (without range filter)
      QuerySnapshot userChallengesSnapshot = await firestore
          .collection('user_challenges')
          .where('userID', isEqualTo: _user!.uid) // Only filter by userID
          .get();
      // Store streak status for each day (Monday-Sunday)
      Map<int, bool> streakDays = {for (int i = 0; i < 7; i++) i: false};
      for (var doc in userChallengesSnapshot.docs) {
        Map<String, dynamic>? challengeData =
            doc.data() as Map<String, dynamic>?;

        if (challengeData == null || !challengeData.containsKey('lastUpdated'))
          continue;

        Timestamp? challengeTimestamp =
            challengeData['lastUpdated'] as Timestamp?;
        if (challengeTimestamp == null) continue;

        DateTime challengeDate = challengeTimestamp.toDate();

        // Manually filter the timestamp in Dart
        if (challengeDate
                .isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            challengeDate.isBefore(endOfWeek.add(const Duration(seconds: 1)))) {
          int dayIndex = challengeDate.weekday - 1; // Convert Mon-Sun to 0-6
          streakDays[dayIndex] = true;
        }
      }

      setState(() {
        _streakDays = streakDays;
      });
    } catch (e) {
      print("Error fetching weekly challenges: $e");
    }
  }

// Map for tracking streak
  Map<int, bool> _streakDays = {for (int i = 0; i < 7; i++) i: false};

// Function to return a check icon if the challenge is completed for that day
  Widget _getStreakIcon(int index) {
    return Icon(
      _streakDays[index] == true ? Icons.check_circle : Icons.cancel,
      color: _streakDays[index] == true ? Colors.green : Colors.grey,
      size: 30,
    );
  }

  // Returns the weekday abbreviation
  String _getWeekdayLabel(int index) {
    const List<String> weekdays = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ];
    return weekdays[index];
  }

  // Returns the current week's date range
  String _getCurrentWeekDateRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Monday
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sunday
    return "${startOfWeek.day} - ${endOfWeek.day} ${_getMonthName(startOfWeek)}";
  }

  // Returns the month name
  static String _getMonthName(DateTime date) {
    const List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[date.month - 1];
  }

  Widget _leaderboardEntry(String name, int points, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Spacer(),
          Text(
            "$points pts",
            style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
