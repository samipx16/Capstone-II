import 'package:flutter/material.dart';
import 'package:ecoeagle/screens/map_screen.dart';
import './widgets/bottom_navbar.dart';

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

  // Get the current weekday index (0 = Monday, 6 = Sunday)
  final int currentDayIndex =
      DateTime.now().weekday - 1; // Adjust index (Monday = 0)

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
                                    value: 65 / 100, // Example progress
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2E7D32)), // Green progress
                                    strokeWidth: 6,
                                  ),
                                ),
                                Icon(Icons.emoji_events,
                                    color: Color(0xFFFAE500), size: 30),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text("65 pts",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold))
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.emoji_events,
                                color: Color(0xFFFAE500), size: 30),
                            SizedBox(height: 4),
                            Text("#7th",
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            Text("Your Rank",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.recycling,
                                color: Color(0xFFFAE500), size: 30),
                            SizedBox(height: 4),
                            Text("13",
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
                          child: Column(
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
                              _leaderboardEntry(
                                  "1. Nia Zhang", 4500, Colors.amber),
                              _leaderboardEntry(
                                  "2. John Cena", 3800, Colors.grey),
                              _leaderboardEntry(
                                  "3. Zack Ryder", 3700, Colors.brown),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Weekly Streak Widget
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

  // Returns the correct streak icon based on the contribution status
  Widget _getStreakIcon(int index) {
    if (index < currentDayIndex) {
      return weeklyContributions[index] == true
          ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
          : const Icon(Icons.cancel, color: Colors.red, size: 30);
    } else if (index == currentDayIndex) {
      return const Icon(Icons.circle, color: Colors.blue, size: 30);
    } else {
      return const Icon(Icons.circle, color: Colors.grey, size: 30);
    }
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
