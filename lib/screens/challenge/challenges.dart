import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  int _currentIndex = 1; // Set Challenges as active tab
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredChallenges = [];

  final List<Map<String, dynamic>> challengeTypes = [
    {
      "title": "Daily Challenges",
      "description":
          "Complete your Daily Challenges to earn your daily points.",
      "icon": Icons.calendar_today,
      "route": "/dailyChallenges",
      "image": "assets/task-img.png",
      "challenges": [
        "Go Plastic-Free Self-report avoiding plastic for a whole day.",
        "Recycle 1 Item Scan QR codes at a recycling bin.",
        "Refill Your Bottle : Refill your water bottle or cup at the refill stations around campus",
        "Public Transport : Report yourself using public transport",
        "Turn-off Lights : Self-report turning off all unnecessary lights",
        "Walk/Bike to Class : Log your walk/bike ride to class",
      ]
    },
    {
      "title": "Weekly Challenges",
      "description": "Complete your Weekly Challenges to earn more points.",
      "icon": Icons.date_range,
      "route": "/weeklyChallenges",
      "image": "assets/task-img.png",
      "challenges": [
        "Avoid Plastics : Avoid single use plastics for a week",
        "Eco-Friendly Purchase : Report an eco-friendly purchase you've made within the week",
        "Local Cleanup Effort : Participate in a local cleanup effort",
        "Meatless Days : Go meatless for at least 3 days of the week",
        "Litter Cleanup : Pick up at least 10 pieces of litter that you see",
      ]
    },
    {
      "title": "One-time Challenges",
      "description":
          "Complete your One-time Challenge to earn a large amount of points.",
      "icon": Icons.verified,
      "route": "/oneTimeChallenges",
      "image": "assets/task-img.png",
      "challenges": [
        "Plant a Tree : Upload a photo of the tree you planted.",
        "Start a Home Garden : Start a home garden",
        "Donate Clothes : Donate your old clothes",
        "Make a Compost Bin : Set up a compost bin",
        "Go to a Recycling Event: Attend a recycling workshop or event in your area"
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _filteredChallenges = List.from(challengeTypes);
    _searchController.addListener(_filterChallenges);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChallenges() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChallenges = challengeTypes.where((category) {
        return category["title"].toLowerCase().contains(query) ||
            category["description"].toLowerCase().contains(query);
      }).toList();
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
                decoration: InputDecoration(
                  hintText: "Search challenges...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Challenge Category Blocks
            Expanded(
              child: _filteredChallenges.isEmpty
                  ? const Center(child: Text("No matching challenges found."))
                  : ListView.builder(
                      itemCount: _filteredChallenges.length,
                      itemBuilder: (context, index) {
                        final category = _filteredChallenges[index];
                        return _buildChallengeCategory(
                          title: category["title"],
                          description: category["description"],
                          icon: category["icon"],
                          route: category["route"],
                          imagePath: category["image"],
                          taskCount: (category["challenges"] as List).length,
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

              // Expanded Title, Description & Task Count
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
                    const SizedBox(height: 6),

                    // Task Count Row (Green Box + "Available Task" Text)
                    Row(
                      children: [
                        // Green rounded task count
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$taskCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // "Available Task" text
                        const Text(
                          "Task Count",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
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
