import 'package:flutter/material.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

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
    );
  }

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
}
