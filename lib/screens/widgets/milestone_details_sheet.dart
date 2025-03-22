import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MilestoneDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> milestone;
  final String milestoneKey;

  const MilestoneDetailsSheet({
    Key? key,
    required this.milestone,
    required this.milestoneKey,
  }) : super(key: key);

  @override
  _MilestoneDetailsSheetState createState() => _MilestoneDetailsSheetState();
}

class _MilestoneDetailsSheetState extends State<MilestoneDetailsSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String challengeTitle = "";
  late int challengeProgress = 0;
  late int challengeGoal = 0;

  final Map<String, Map<String, dynamic>> milestoneToChallengeMap = {
    "milestone_1": {"id": "recycle_5", "title": "Recycle 5 Items", "goal": 50},
    "milestone_2": {"id": "go_plastic_free", "title": "Go Plastic Free", "goal": 7},
    "milestone_3": {"id": "walk_to_class", "title": "Walk/Bike to Class", "goal": 10},
    "milestone_4": {"id": "refill_station", "title": "Use Refill Stations", "goal": 20},
    "milestone_5": {"id": "meatless_week", "title": "Meatless Week", "goal": 10},
  };

  @override
  void initState() {
    super.initState();
    _fetchChallengeData();
  }

  Future<void> _fetchChallengeData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (widget.milestoneKey == 'milestone_6') {
      final userMilestonesDoc = await _firestore.collection('user_milestones').doc(user.uid).get();
      if (userMilestonesDoc.exists) {
        final data = userMilestonesDoc.data()!;
        int completedMilestones = 0;
        for (int i = 1; i <= 5; i++) {
          if (data['milestone_$i'] != null && data['milestone_$i']['completed'] == true) {
            completedMilestones++;
          }
        }

        setState(() {
          challengeTitle = "Complete All 5 Milestones";
          challengeProgress = completedMilestones;
          challengeGoal = 5;
        });
      } else {
        setState(() {
          challengeTitle = "Complete All 5 Milestones";
          challengeProgress = 0;
          challengeGoal = 5;
        });
      }
      return;
    }

    if (milestoneToChallengeMap.containsKey(widget.milestoneKey)) {
      final challengeInfo = milestoneToChallengeMap[widget.milestoneKey]!;
      final challengeId = challengeInfo['id'];
      final challengeGoal = challengeInfo['goal'];

      final challengeDoc = await _firestore
          .collection('user_challenges')
          .doc("${user.uid}_$challengeId")
          .get();

      int completions = challengeDoc.exists
          ? (challengeDoc.data()?['completedChallengesCount'] ?? 0)
          : 0;

      setState(() {
        challengeTitle = challengeInfo['title'];
        challengeProgress = completions;
        this.challengeGoal = challengeGoal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/${widget.milestoneKey}.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                widget.milestone['title'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "${widget.milestone['progress']} / ${widget.milestone['goal']} completed",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              Text(
                _getMilestoneDescription(widget.milestone['title']),
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
              SizedBox(height: 16),
              Expanded(
                child: challengeTitle.isNotEmpty
                    ? ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text(challengeTitle),
                      subtitle: Text("Completed $challengeProgress / $challengeGoal"),
                    ),
                  ],
                )
                    : Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        );
      },
    );
  }

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
