import 'package:flutter/material.dart';

class MilestoneDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> milestone;
  final String milestoneKey;

  const MilestoneDetailsSheet({
    Key? key,
    required this.milestone,
    required this.milestoneKey,
  }) : super(key: key);

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
              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Badge Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/$milestoneKey.png', // Load the badge image dynamically
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                  },
                ),
              ),

              SizedBox(height: 16),

              // Milestone Title
              Text(
                milestone['title'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // Progress
              Text(
                "${milestone['progress']} / ${milestone['goal']} completed",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 16),

              // Description
              Text(
                _getMilestoneDescription(milestone['title']),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),

              SizedBox(height: 16),

              // Related Challenges (Example)
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: Icon(Icons.recycling, color: Colors.green),
                      title: Text("Recycle 5 Items"),
                      subtitle: Text("Completed 3/5"),
                    ),
                    ListTile(
                      leading: Icon(Icons.water_drop, color: Colors.blue),
                      title: Text("Use Refill Stations"),
                      subtitle: Text("Completed 10/20"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get milestone description
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