import 'package:flutter/material.dart';
import 'package:ecoeagle/screens/map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
      appBar: AppBar(title: const Text("Welcome Back")),
      body: Container(
        color: Colors.green.shade800, // Green background for the whole page
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                "Good Morning, Sustainability Hero!",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(26.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Column(
                        children: [
                          Icon(Icons.emoji_events,
                              color: Color(0xFFFAE500), size: 30),
                          Text("65 pts", style: TextStyle(fontSize: 20))
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.leaderboard,
                              color: Color(0xFFFAE500), size: 30),
                          Text("#7th Rank", style: TextStyle(fontSize: 20))
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.recycling,
                              color: Color(0xFFFAE500), size: 30),
                          Text("13 Recycled", style: TextStyle(fontSize: 20))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // Row for Map and Leaderboard Widgets
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 130,
                      child: Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: const Icon(Icons.map, color: Colors.green),
                          title: const Text("Find the closest Recycle Bin"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MapScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 130,
                      child: Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Leaderboard",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              SizedBox(height: 8),
                              Text("#1 - Niz Zhang"),
                              Text("#2 - John Cena"),
                              Text("#3 - Zack Ryder"),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 6.0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
              child: Row(
                children: [
                  // Left side items (spaced evenly)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBottomNavItem(
                          index: 0,
                          icon: Icons.home,
                          label: "Home",
                          onPressed: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                          },
                        ),
                        _buildBottomNavItem(
                          index: 1,
                          icon: Icons.emoji_events,
                          label: "Challenges",
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                            Navigator.pushNamed(context, '/challenges');
                          },
                          offset: -10, // shift Challenges left
                        ),
                      ],
                    ),
                  ),
                  // Right side items (spaced evenly)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBottomNavItem(
                          index: 2,
                          icon: Icons.star,
                          label: "Milestones",
                          onPressed: () {
                            setState(() {
                              _currentIndex = 2;
                            });
                            Navigator.pushNamed(context, '/milestones');
                          },
                        ),
                        _buildBottomNavItem(
                          index: 3,
                          icon: Icons.account_circle,
                          label: "Accounts",
                          onPressed: () {
                            setState(() {
                              _currentIndex = 3;
                            });
                            Navigator.pushNamed(context, '/accounts');
                          },
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
    );
  }

  // Helper method to build a bottom nav item with an optional horizontal offset.
  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double offset = 0.0,
  }) {
    // Use green if the current nav item is active, grey otherwise.
    Color activeColor = Colors.green;
    Color inactiveColor = Colors.grey;
    bool isActive = _currentIndex == index;
    Color itemColor = isActive ? activeColor : inactiveColor;

    return MaterialButton(
      onPressed: onPressed,
      minWidth: 40,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: itemColor),
            Text(label, style: TextStyle(color: itemColor, fontSize: 12)),
          ],
        ),
      ),
    );
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
}
