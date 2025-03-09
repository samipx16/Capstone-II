import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class MilestonePopup extends StatefulWidget {
  final String milestoneId;
  final String milestoneTitle;

  const MilestonePopup({
    Key? key,
    required this.milestoneId,
    required this.milestoneTitle,
  }) : super(key: key);

  // Static method to show the popup
  static void show(BuildContext context, String milestoneId, String milestoneTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MilestonePopup(milestoneId: milestoneId, milestoneTitle: milestoneTitle);
      },
    );
  }

  @override
  _MilestonePopupState createState() => _MilestonePopupState();
}

class _MilestonePopupState extends State<MilestonePopup> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play(); // Start confetti animation
  }

  @override
  void dispose() {
    _confettiController.dispose(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set image path based on Firestore milestone ID
    String imagePath = "assets/${widget.milestoneId}.png";

    return Stack(
      children: [
        // 🎉 Confetti Animation
        Positioned.fill(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.yellow],
          ),
        ),

        // 🏆 Milestone Badge Pop-Up
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Image.asset(
                imagePath,
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.emoji_events, size: 100, color: Colors.green); // Default icon if image is missing
                },
              ),
              const SizedBox(height: 10),
              const Text("🎉 Achievement Unlocked!"),
            ],
          ),
          content: Text(
            "You just completed the **${widget.milestoneTitle}** milestone!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _confettiController.stop();
                Navigator.of(context).pop();
              },
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}