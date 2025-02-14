import 'package:flutter/material.dart';
import 'package:ecoeagle/screens/map_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({Key? key}) : super(key: key);

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
  final int currentDayIndex = DateTime.now().weekday - 1; // Adjust index (Monday = 0)

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
                      Column(children: [
                        Icon(Icons.emoji_events, color: const Color(0xFFFAE500), size: 30),
                        Text("65 pts",
                          style: TextStyle(fontSize: 20),)
                      ]),
                      Column(children: [
                        Icon(Icons.leaderboard, color: const Color(0xFFFAE500), size: 30),
                        Text("#7th Rank",
                          style: TextStyle(fontSize: 20),)
                      ]),
                      Column(children: [
                        Icon(Icons.recycling, color: const Color(0xFFFAE500), size: 30),
                        Text("13 Recycled",
                          style: TextStyle(fontSize: 20),)
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

// Row for Map and Leaderboard Widgets
              Row(
                children: [
                  // Map Card - Same size as Leaderboard
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
                              MaterialPageRoute(builder: (context) => MapScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10), // Spacing between Map and Leaderboard

                  // Leaderboard Placeholder - Same size as Map
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
                              Text(
                                "Leaderboard",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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
                        "This Week -  ${_getCurrentWeekDateRange()}",
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
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipPath(
            clipper: BottomNavBarClipper(),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.green, // Selected icon color
              unselectedItemColor: Colors.grey, // Unselected icon color
              showUnselectedLabels: true, // Ensure all labels are always visible
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Challenges"),
                BottomNavigationBarItem(icon: Icon(Icons.star), label: "Milestones"),
                BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () {},
              child: const Icon(Icons.qr_code, color: Colors.white),
            ),
          ),
        ],
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
    const List<String> weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return weekdays[index];
  }

  // Returns the current week's date range
  static String _getCurrentWeekDateRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sunday

    return "${startOfWeek.day} - ${endOfWeek.day} ${_getMonthName(startOfWeek)}";
  }

  // Returns the month name
  static String _getMonthName(DateTime date) {
    const List<String> months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[date.month - 1];
  }
}

class BottomNavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width * 0.4, 0);
    path.quadraticBezierTo(size.width * 0.5, 50, size.width * 0.6, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
