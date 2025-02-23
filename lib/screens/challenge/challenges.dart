import 'package:flutter/material.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  int _currentIndex = 1; // Set Challenges as active tab

  final List<Map<String, dynamic>> challengeTypes = [
    {
      "title": "Daily Challenges",
      "description":
          "Complete your Daily Challenges to earn your daily points.",
      "icon": Icons.calendar_today,
      "route": "/dailyChallenges",
    },
    {
      "title": "Weekly Challenges",
      "description": "Complete your Weekly Challenges to earn more points.",
      "icon": Icons.date_range,
      "route": "/weeklyChallenges",
    },
    {
      "title": "Monthly Challenges",
      "description": "Complete your Monthly Challenges to earn big rewards.",
      "icon": Icons.event,
      "route": "/monthlyChallenges",
    },
    {
      "title": "One-time Challenges",
      "description": "Complete your One-time Challenge to get large points.",
      "icon": Icons.verified,
      "route": "/oneTimeChallenges",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Challenges"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Menu button clicked")),
              );
            },
          ),
        ],
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
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Challenge Category Blocks
            Expanded(
              child: ListView.builder(
                itemCount: challengeTypes.length,
                itemBuilder: (context, index) {
                  final challenge = challengeTypes[index];
                  return _buildChallengeCategory(
                    title: challenge["title"],
                    description: challenge["description"],
                    icon: challenge["icon"],
                    route: challenge["route"],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // QR Code Floating Action Button
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
      bottomNavigationBar: SafeArea(
        top: false,
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
                          route: '/dashboard'),
                      _buildBottomNavItem(
                          index: 1,
                          icon: Icons.emoji_events,
                          label: "Challenges",
                          route: ''),
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
                          route: '/milestones'),
                      _buildBottomNavItem(
                          index: 3,
                          icon: Icons.account_circle,
                          label: "Accounts",
                          route: '/accounts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCategory({
    required String title,
    required String description,
    required IconData icon,
    required String route,
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
            children: [
              // Icon on the left
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green.shade100,
                child: Icon(icon, color: Colors.green, size: 30),
              ),
              const SizedBox(width: 16),
              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              // Navigation Arrow
              const Icon(Icons.arrow_forward_ios, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required String route,
  }) {
    bool isActive = _currentIndex == index;
    return MaterialButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
        if (route.isNotEmpty) {
          Navigator.pushNamed(context, route);
        }
      },
      minWidth: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.green : Colors.grey),
          Text(label,
              style: TextStyle(
                  color: isActive ? Colors.green : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
