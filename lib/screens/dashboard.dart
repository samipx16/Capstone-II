import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecoeagle/screens/map_screen.dart';
import './widgets/bottom_navbar.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import './widgets/qr_helper.dart';
import './qr_scanner_screen.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Index for the active bottom nav item (0: Home, 1: Challenges, 2: Milestones, 3: Account)
  int _currentIndex = 0;
  BitmapDescriptor? _customIcon;

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
    _loadCustomMarker();
    _fetchTopThree();
    _user = _auth.currentUser;
    _fetchUserPoints();
    _fetchUserRank();
    _fetchRecycle();
    _fetchWeeklyChallenges();
  }

  Future<void> _loadCustomMarker() async {
    final ByteData byteData = await rootBundle.load('assets/trash-can.webp');
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 64, // width in pixels
      targetHeight: 64, // height in pixels
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteDataPng = await image.toByteData(format: ui.ImageByteFormat.png);
    final resizedBytes = byteDataPng!.buffer.asUint8List();

    _customIcon = BitmapDescriptor.fromBytes(resizedBytes);
    setState(() {});
  }

  Future<void> _fetchUserPoints() async {
    try {
      _user = _auth.currentUser;
      if (_user == null) return;

      String userId = _user!.uid;

      // Fetch lifetime points directly from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        int lifetimePoints = userData['lifetimePoints'] ?? 0;

        // Update state with fetched lifetime points
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

      final doc = await _firestore
          .collection('user_challenges')
          .doc('${_user!.uid}_recycle_5')
          .get();

      int completions =
          doc.exists ? (doc.data()?['completedChallengesCount'] ?? 0) : 0;

      setState(() {
        _userRecycled = completions;
      });

      debugPrint('✅ recycle_5 completions count from counter: $completions');
    } catch (e) {
      debugPrint('❌ Error fetching recycle completions: $e');
    }
  }

  Future<Map<String, double>> fetchUserImpact() async {
    final userId = _user!.uid;

    final challenges = [
      {'id': 'recycle_5', 'multiplier': 0.25, 'metric': 'co2'},
      {'id': 'refill_station', 'multiplier': 5.0, 'metric': 'water'},
      {'id': 'pick_up_litter', 'multiplier': 1.0, 'metric': 'waste'},
    ];

    double totalCO2 = 0;
    double totalWater = 0;
    double totalWaste = 0;

    for (var challenge in challenges) {
      final doc = await _firestore
          .collection('user_challenges')
          .doc('${userId}_${challenge['id']}')
          .get();

      int completions =
          doc.exists ? (doc.data()?['completedChallengesCount'] ?? 0) : 0;

      double impact = completions * (challenge['multiplier'] as double);

      if (challenge['metric'] == 'co2') {
        totalCO2 = impact;
      } else if (challenge['metric'] == 'water') {
        totalWater = impact;
      } else if (challenge['metric'] == 'waste') {
        totalWaste = impact;
      }
    }

    return {
      'co2': totalCO2,
      'water': totalWater,
      'waste': totalWaste,
    };
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
        body: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
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
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                        child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    "${_getGreeting()}, Sustainability Hero!",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
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
                                        value:
                                            (_userPoints / 100).clamp(0.0, 1.0),
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Color(0xFF2E7D32)),
                                        strokeWidth: 6,
                                      ),
                                    ),
                                    const Icon(Icons.star,
                                        color: Color(0xFFFAE500), size: 30),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "$_userPoints pts",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  "Your Points",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF8E1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.emoji_events,
                                      color: Color(0xFFFAE500), size: 30),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "#$_userRank",
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                const Text(
                                  "Your Rank",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.recycling,
                                      color: Color(0xFF03AC52), size: 30),
                                ),
                                SizedBox(height: 8),
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
                          height: 180,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MapScreen()),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    GoogleMap(
                                      initialCameraPosition:
                                          const CameraPosition(
                                        target: LatLng(33.2075, -97.152613),
                                        zoom: 14,
                                      ),
                                      zoomControlsEnabled: false,
                                      scrollGesturesEnabled: false,
                                      rotateGesturesEnabled: false,
                                      tiltGesturesEnabled: false,
                                      myLocationButtonEnabled: false,
                                      markers: {
                                        Marker(
                                          markerId:
                                              MarkerId("recycle_bin_preview"),
                                          position: LatLng(33.2075, -97.152613),
                                          icon: _customIcon ??
                                              BitmapDescriptor.defaultMarker,
                                          infoWindow: InfoWindow(
                                              title: "UNT Recycle Bin Preview"),
                                        ),
                                      },
                                    ),
                                    Container(
                                      color: Colors.black.withAlpha(150),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          // Icon(Icons.location_on, color: Colors.black, size: 40),
                                          SizedBox(height: 6),
                                          Text(
                                            "Map",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Tap to find bins",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 180,
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Leaderboard",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(Icons.star, color: Colors.amber),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _leaderboardEntry(
                                        "1. ${topThree[0]['name'].split(' ').first}",
                                        topThree[0]['score'],
                                        Colors.amber,
                                      ),
                                      if (topThree.length > 1)
                                        _leaderboardEntry(
                                          "2. ${topThree[1]['name'].split(' ').first}",
                                          topThree[1]['score'],
                                          Colors.grey,
                                        ),
                                      if (topThree.length > 2)
                                        _leaderboardEntry(
                                          "3. ${topThree[2]['name'].split(' ').first}",
                                          topThree[2]['score'],
                                          Colors.brown,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Weekly Streak Card
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
                                  _getStreakIcon(index),
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
                  SizedBox(height: 16),
                  // Environmental Impact Card
                  FutureBuilder<Map<String, double>>(
                    future: fetchUserImpact(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                            child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: CircularProgressIndicator()),
                        ));
                      }

                      final impactData =
                          snapshot.data ?? {'co2': 0, 'water': 0, 'waste': 0};

                      return Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    "Your Environmental Impact",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _impactMetric(
                                    icon: Icons.co2,
                                    value:
                                        impactData['co2']!.toStringAsFixed(1),
                                    label: "CO₂ Saved",
                                    unit: "kg",
                                    color: Colors.blue,
                                  ),
                                  _impactMetric(
                                    icon: Icons.water_drop,
                                    value:
                                        impactData['water']!.toStringAsFixed(0),
                                    label: "Water Saved",
                                    unit: "L",
                                    color: Colors.lightBlue,
                                  ),
                                  _impactMetric(
                                    icon: Icons.delete_outline,
                                    value:
                                        impactData['waste']!.toStringAsFixed(1),
                                    label: "Waste Diverted",
                                    unit: "kg",
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),)
              ),
              );
            },
        ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );

          if (result != null) {
            await handleUniversalQRScan(context, result);
          }
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

  // Helper method for impact metrics
  Widget _impactMetric({
    required IconData icon,
    required String value,
    required String label,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 16),
            children: [
              TextSpan(
                text: value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextSpan(text: " $unit"),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
