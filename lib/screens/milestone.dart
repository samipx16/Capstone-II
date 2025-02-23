import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MilestonesPage extends StatefulWidget {
  @override
  _MilestonesPageState createState() => _MilestonesPageState();
}

class _MilestonesPageState extends State<MilestonesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String uid;
  int _currentIndex = 2; // Set Milestones as active tab

  @override
  void initState() {
    super.initState();
    _fetchUserAndInitialize();
  }

  void _fetchUserAndInitialize() async {
    User? user = _auth.currentUser;

    if (user != null) {
      setState(() {
        uid = user.uid;
      });

      await _initializeUserMilestones();
      _listenToChallengeUpdates();
    }
  }

  Future<void> _initializeUserMilestones() async {
    DocumentReference userMilestonesRef = _firestore.collection('user_milestones').doc(uid);
    DocumentSnapshot snapshot = await userMilestonesRef.get();

    if (!snapshot.exists) {
      await userMilestonesRef.set({
        "milestone_1": {"title": "Scrappy Recycler", "goal": 50, "progress": 0},
        "milestone_2": {"title": "Mean Green Warrior", "goal": 7, "progress": 0},
        "milestone_3": {"title": "Lucky Commuter", "goal": 10, "progress": 0},
        "milestone_4": {"title": "Hydration Hawk", "goal": 20, "progress": 0},
        "milestone_5": {"title": "Eco Eagle", "goal": 10, "progress": 0},
        "milestone_6": {"title": "Ultimate Mean Green Hero", "goal": 5, "progress": 0},
      });
    }
  }

  void _listenToChallengeUpdates() {
    _firestore.collection('user_challenges').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _syncMilestonesWithChallenges(snapshot.data() as Map<String, dynamic>);
      }
    });
  }

  Future<void> _syncMilestonesWithChallenges(Map<String, dynamic> userChallenges) async {
    DocumentReference userMilestonesRef = _firestore.collection('user_milestones').doc(uid);
    Map<String, dynamic> milestoneUpdates = {};

    if (userChallenges.containsKey('recycle_5')) {
      milestoneUpdates['milestone_1.progress'] = (userChallenges['recycle_5']['count'] * 5).clamp(0, 50);
    }
    if (userChallenges.containsKey('go_plastic_free')) {
      milestoneUpdates['milestone_2.progress'] = userChallenges['go_plastic_free']['count'].clamp(0, 7);
    }
    if (userChallenges.containsKey('walk_to_class')) {
      milestoneUpdates['milestone_3.progress'] = userChallenges['walk_to_class']['count'].clamp(0, 10);
    }

    await userMilestonesRef.update(milestoneUpdates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Milestones"), backgroundColor: Colors.green),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('user_milestones').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No milestones found."));
          }

          Map<String, dynamic> milestones = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: milestones.entries.map((entry) {
              String key = entry.key;
              Map<String, dynamic> data = entry.value;

              return _buildMilestoneCard(data, key);
            }).toList(),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.pushNamed(context, '/qr_scan');
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,


      // Bottom Navigation Bar (Copied from Challenges Page)
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomNavItem(
                          index: 0, icon: Icons.home, label: "Home", route: '/dashboard'),
                      _buildBottomNavItem(
                          index: 1, icon: Icons.emoji_events, label: "Challenges", route: '/challenges'),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomNavItem(
                          index: 2, icon: Icons.star, label: "Milestones", route: ''),
                      _buildBottomNavItem(
                          index: 3, icon: Icons.account_circle, label: "Accounts", route: '/accounts'),
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

  Widget _buildMilestoneCard(Map<String, dynamic> milestone, String key) {
    double progressPercent = (milestone['progress'] / milestone['goal']).clamp(0.0, 1.0);
    String badgePath = 'assets/$key.png'; // Path based on milestone key

    print("📸 Loading local badge: $badgePath"); // Debugging

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Load Badge Image from Local Assets
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                badgePath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print("❌ Error loading image: $badgePath");
                  return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
                },
              ),
            ),

            const SizedBox(width: 16),

            // Milestone Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone['title'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${milestone['progress']} / ${milestone['goal']} completed",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
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
