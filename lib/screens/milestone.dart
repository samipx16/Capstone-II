import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './widgets/bottom_navbar.dart';

class MilestonesPage extends StatefulWidget {
  const MilestonesPage({super.key});

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

  /// Fetches the current user and initializes their milestones if not present.
  void _fetchUserAndInitialize() async {
    User? user = _auth.currentUser;

    if (user != null) {
      setState(() {
        uid = user.uid;
      });

      // Ensure milestones are initialized for the new user
      await _initializeUserMilestones();
    }
  }

  /// Ensures that the new user has a milestone document in Firestore.
  Future<void> _initializeUserMilestones() async {
    DocumentReference userMilestonesRef =
    _firestore.collection('user_milestones').doc(uid);
    DocumentSnapshot snapshot = await userMilestonesRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      print("Initializing milestones for new user: $uid");

      await userMilestonesRef.set({
        "milestone_1": {
          "title": "Scrappy Recycler",
          "goal": 50,
          "progress": 0
        },
        "milestone_2": {
          "title": "Mean Green Warrior",
          "goal": 7,
          "progress": 0
        },
        "milestone_3": {
          "title": "Lucky Commuter",
          "goal": 10,
          "progress": 0
        },
        "milestone_4": {
          "title": "Hydration Hawk",
          "goal": 20,
          "progress": 0
        },
        "milestone_5": {
          "title": "Eco Eagle",
          "goal": 10,
          "progress": 0
        },
        "milestone_6": {
          "title": "Ultimate Mean Green Hero",
          "goal": 5,
          "progress": 0
        },
      });
    } else {
      print("Milestones already exist for user.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Milestones",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('user_milestones').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Loading milestones..."));
          }

          Map<String, dynamic>? milestones =
          snapshot.data!.data() as Map<String, dynamic>?;

          if (milestones == null || milestones.isEmpty) {
            return const Center(
                child: Text(
                  "No milestones available. Please try again later.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: milestones.entries.map((entry) {
              return _buildMilestoneCard(entry.value, entry.key);
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

  /// Builds each milestone card with improved layout, bigger images, and descriptions.
  Widget _buildMilestoneCard(Map<String, dynamic> milestone, String key) {
    double progressPercent =
    (milestone['progress'] / milestone['goal']).clamp(0.0, 1.0);
    String badgePath = 'assets/$key.png';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Larger Badge Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                badgePath,
                width: 80, // Bigger badge
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported,
                      size: 80, color: Colors.grey);
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
                    style: const TextStyle(
                      fontSize: 20, // Bigger font
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Short Description (Lower Opacity)
                  Text(
                    _getMilestoneDescription(milestone['title']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Thicker Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                      minHeight: 12, // Increased thickness
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "${milestone['progress']} / ${milestone['goal']} completed",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Provides descriptions for each milestone
  String _getMilestoneDescription(String title) {
    switch (title) {
      case "Scrappy Recycler":
        return "Recycle 50 items to earn this badge!";
      case "Mean Green Warrior":
        return "Avoid plastic for a week!";
      case "Lucky Commuter":
        return "Walk or bike to class 10 times!";
      case "Hydration Hawk":
        return "Use refill stations 20 times!";
      case "Eco Eagle":
        return "Reduce food waste 10 times!";
      case "Ultimate Mean Green Hero":
        return "Complete all milestones!";
      default:
        return "Complete challenges to unlock!";
    }
  }
}
