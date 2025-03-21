import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './widgets/bottom_navbar.dart';
import './widgets/milestone_popup.dart';
import './widgets/milestone_details_sheet.dart';

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

      await _fetchCompletedChallengesCount();
      // Ensure milestones are initialized for the new user
      await _initializeUserMilestones();

      // Start listening for challenge updates
      _listenToChallengeUpdates();

      // Rescan challenges and sync milestones when the user logs in
      //await rescanChallengesAndSyncMilestones();
    }
  }

  Future<void> _fetchCompletedChallengesCount() async {
    QuerySnapshot userChallengesSnapshot = await _firestore
        .collection('user_challenges')
        .where('userID', isEqualTo: uid)
        .get();

    for (var doc in userChallengesSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      int completedCount = data['completedChallengesCount'] ?? 0;
      debugPrint(
          "✅ Challenge ${data['challengeID']} has been completed $completedCount times.");
    }
  }

  void _listenToChallengeUpdates() {
    _firestore
        .collection('user_challenges')
        .where('userID', isEqualTo: uid) // Filter by current user
        .snapshots()
        .listen((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userChallengeData =
            doc.data() as Map<String, dynamic>;

        int completedCount = userChallengeData['completedChallengesCount'] ?? 0;

        debugPrint(
            "📌 Challenge ${userChallengeData['challengeID']} completed $completedCount times.");

        _syncMilestonesWithChallenges(userChallengeData);
      }
    });
  }

  Future<void> _syncMilestonesWithChallenges(
      Map<String, dynamic> userChallenges) async {
    DocumentReference userMilestonesRef =
        _firestore.collection('user_milestones').doc(uid);
    Map<String, dynamic> milestoneUpdates = {};
    List<Map<String, String>> completedMilestones = [];

    // Fetch the current milestone data
    DocumentSnapshot milestoneSnapshot = await userMilestonesRef.get();
    Map<String, dynamic> currentMilestones =
        milestoneSnapshot.data() as Map<String, dynamic>;

    final List<Map<String, dynamic>> challenges = [
      {
        'id': 'recycle_5',
        'milestone': 'milestone_1',
        'title': 'Scrappy Recycler',
        'goal': 50
      },
      {
        'id': 'go_plastic_free',
        'milestone': 'milestone_2',
        'title': 'Mean Green Warrior',
        'goal': 7
      },
      {
        'id': 'walk_to_class',
        'milestone': 'milestone_3',
        'title': 'Lucky Commuter',
        'goal': 10
      },
      {
        'id': 'refill_station',
        'milestone': 'milestone_4',
        'title': 'Hydration Hawk',
        'goal': 20
      },
      {
        'id': 'meatless_week',
        'milestone': 'milestone_5',
        'title': 'Eco Eagle',
        'goal': 10
      },
    ];

    for (var challenge in challenges) {
      if (userChallenges['challengeID'] == challenge['id']) {
        int completedCount = userChallenges['completedChallengesCount'] ?? 0;
        bool isCompleted = completedCount >= challenge['goal'];

        // Check if the milestone is completed for the first time
        if (isCompleted &&
            currentMilestones[challenge['milestone']]['completed'] != true) {
          completedMilestones
              .add({'id': challenge['milestone'], 'title': challenge['title']});
        }

        // Update progress and completed status
        milestoneUpdates['${challenge['milestone']}.progress'] =
            completedCount.clamp(0, challenge['goal']);
        milestoneUpdates['${challenge['milestone']}.completed'] = isCompleted;
      }
    }

    // 🏆 Ultimate Mean Green Hero → Complete All Milestones
    bool allMilestonesCompleted = milestoneUpdates.length == 5 &&
        milestoneUpdates.values.every((value) => value >= 1);

    if (allMilestonesCompleted &&
        currentMilestones['milestone_6']['completed'] != true) {
      completedMilestones
          .add({"id": "milestone_6", "title": "Ultimate Mean Green Hero"});
      milestoneUpdates['milestone_6.progress'] = 5; // Set to max (goal = 5)
      milestoneUpdates['milestone_6.completed'] = true;
    }

    // 🚀 Update Firestore if any milestone progress changed
    if (milestoneUpdates.isNotEmpty) {
      await userMilestonesRef.update(milestoneUpdates);
      print("🚀 Updated milestones: $milestoneUpdates");
    }

    // 🎉 Show animation if any new milestone is completed
    if (completedMilestones.isNotEmpty) {
      for (var milestone in completedMilestones) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MilestonePopup.show(context, milestone["id"]!, milestone["title"]!);
        });
      }
    }
  }

  Future<void> rescanChallengesAndSyncMilestones() async {
    DocumentSnapshot challengeSnapshot =
        await _firestore.collection('user_challenges').doc(uid).get();
    DocumentSnapshot milestoneSnapshot =
        await _firestore.collection('user_milestones').doc(uid).get();

    if (!challengeSnapshot.exists || !milestoneSnapshot.exists) {
      print("⚠️ No existing challenge or milestone data found.");
      return;
    }

    Map<String, dynamic> userChallenges =
        challengeSnapshot.data() as Map<String, dynamic>;
    Map<String, dynamic> userMilestones =
        milestoneSnapshot.data() as Map<String, dynamic>;
    Map<String, dynamic> milestoneUpdates = {};

    // 🔥 Rescan "Go Plastic-Free" Challenge and Sync it with "Mean Green Warrior"
    if (userChallenges.containsKey('go_plastic_free')) {
      int challengeProgress =
          userChallenges['go_plastic_free']?['progress'] ?? 0;
      int currentMilestoneProgress =
          userMilestones['milestone_2']?['progress'] ?? 0;

      if (challengeProgress > currentMilestoneProgress) {
        print("🔄 Resyncing 'Mean Green Warrior' milestone progress.");
        milestoneUpdates['milestone_2.progress'] =
            challengeProgress.clamp(0, 7);
      }
    }

    // 🔥 Rescan "Recycle 5 Items" Challenge and Sync with "Scrappy Recycler"
    if (userChallenges.containsKey('recycle_5')) {
      int recycleProgress = (userChallenges['recycle_5']?['progress'] ?? 0) * 5;
      int currentMilestoneProgress =
          userMilestones['milestone_1']?['progress'] ?? 0;

      if (recycleProgress > currentMilestoneProgress) {
        print("🔄 Resyncing 'Scrappy Recycler' milestone progress.");
        milestoneUpdates['milestone_1.progress'] = recycleProgress.clamp(0, 50);
      }
    }

    if (milestoneUpdates.isNotEmpty) {
      print("🚀 Resyncing milestones with Firestore: $milestoneUpdates");
      await _firestore
          .collection('user_milestones')
          .doc(uid)
          .update(milestoneUpdates);
    } else {
      print("✅ Milestones are already up to date.");
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
          "progress": 0,
          "completed": false
        },
        "milestone_2": {
          "title": "Mean Green Warrior",
          "goal": 7,
          "progress": 0,
          "completed": false
        },
        "milestone_3": {
          "title": "Lucky Commuter",
          "goal": 10,
          "progress": 0,
          "completed": false
        },
        "milestone_4": {
          "title": "Hydration Hawk",
          "goal": 20,
          "progress": 0,
          "completed": false
        },
        "milestone_5": {
          "title": "Eco Eagle",
          "goal": 10,
          "progress": 0,
          "completed": false
        },
        "milestone_6": {
          "title": "Ultimate Mean Green Hero",
          "goal": 5,
          "progress": 0,
          "completed": false
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

  // Add the showMilestoneDetails method here
  void showMilestoneDetails(
      BuildContext context, Map<String, dynamic> milestone, String key) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MilestoneDetailsSheet(milestone: milestone, milestoneKey: key);
      },
    );
  }

  /// Builds each milestone card with improved layout, bigger images, and descriptions.
  Widget _buildMilestoneCard(Map<String, dynamic> milestone, String key) {
    double progressPercent =
        (milestone['progress'] / milestone['goal']).clamp(0.0, 1.0);
    bool isCompleted = milestone['completed'] == true;
    String badgePath = 'assets/$key.png';

    return GestureDetector(
      onTap: () => showMilestoneDetails(context, milestone, key),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  badgePath,
                  width: 80,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Short Description
                    Text(
                      _getMilestoneDescription(milestone['title']),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Progress Text
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
