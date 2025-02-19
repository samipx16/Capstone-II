import 'package:flutter/material.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  // Active nav item (0: Home, 1: Challenges, 2: Milestones, 3: Account)
  int _currentIndex = 1; // Set Challenges as active

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Challenges"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Available Challenges",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildChallengeCard("Recycle 5 Items",
                      "Scan QR codes at 5 different recycling bins."),
                  _buildChallengeCard("Go Plastic-Free",
                      "Self-report avoiding plastic for a whole day."),
                  _buildChallengeCard("Walk/Bike to Class",
                      "Manually log a walk or bike ride to class."),
                  _buildChallengeCard("Reduce Food Waste",
                      "Upload a photo of your finished meal."),
                ],
              ),
            ),
          ],
        ),
      ),
      // Floating QR Code Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          // Define your action here
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Bottom Navigation Bar with a notch for the FAB
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
                  // Left side items
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
                            Navigator.pushNamed(context, '/dashboard');
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
                            // Already on challenges screen
                          },
                          offset: -10, // Slight left shift if needed
                        ),
                      ],
                    ),
                  ),
                  // Right side items
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
                          label: "Account",
                          onPressed: () {
                            setState(() {
                              _currentIndex = 3;
                            });
                            Navigator.pushNamed(context, '/account');
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

  // Builds a card for a given challenge
  Widget _buildChallengeCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text("Start"),
        ),
      ),
    );
  }

  // Helper to build a bottom nav item
  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double offset = 0.0,
  }) {
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
}
