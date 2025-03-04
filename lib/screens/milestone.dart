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

  void _fetchUserAndInitialize() async {
    User? user = _auth.currentUser;

    if (user != null) {
      setState(() {
        uid = user.uid;
      });
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
            return const Center(child: Text("No milestones found."));
          }

          Map<String, dynamic> milestones =
          snapshot.data!.data() as Map<String, dynamic>;

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
                width: 80, // Increased size
                height: 80, // Increased size
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

  // Function to get milestone descriptions
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

