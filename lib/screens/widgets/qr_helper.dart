import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> handleUniversalQRScan(
    BuildContext context, String scannedCode) async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;

  if (user == null) return;

  debugPrint("📲 Scanned QR Code: $scannedCode");

  // Map QR to Challenge ID
  Map<String, String> qrToChallengeMap = {
    "BIN_01": "recycle_5",
    "WATER_01": "refill_station",
  };

  final challengeID = qrToChallengeMap[scannedCode];

  if (challengeID == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Unknown QR Code")),
    );
    return;
  }

  final docRef =
      firestore.collection('user_challenges').doc("${user.uid}_$challengeID");

  try {
    DocumentSnapshot doc = await docRef.get();
    int currentProgress = 0;
    int requiredProgress = 1;
    Timestamp? lastUpdated;
    bool canUpdate = true;

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      currentProgress = data['progress'] ?? 0;
      lastUpdated = data['lastUpdated'];
    }

    // Check cooldown
    DateTime now = DateTime.now();
    if (lastUpdated != null) {
      final lastTime = lastUpdated.toDate();
      final difference = now.difference(lastTime);

      if (difference.inHours < 24) {
        int hoursLeft = 24 - difference.inHours;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "⏳ You have completed this challenge. Try again in $hoursLeft hour(s).")),
        );
        return;
      }
    }

    //  Update progress (without touching lastUpdated yet)
    int newProgress = currentProgress + 1;
    bool isCompleted = newProgress >= requiredProgress;
    String status = isCompleted ? 'completed' : 'in_progress';

    //  Create update data
    Map<String, dynamic> updateData = {
      'challengeID': challengeID,
      'userID': user.uid,
      'progress': newProgress,
      'status': status,
    };

    // Only update lastUpdated if 24+ hours passed
    if (lastUpdated == null ||
        now.difference(lastUpdated.toDate()).inHours >= 24) {
      updateData['lastUpdated'] = FieldValue.serverTimestamp();
    }

    // Merge update
    await docRef.set(updateData, SetOptions(merge: true));

    // If completed, increment completedChallengesCount
    if (isCompleted) {
      await docRef.update({
        'completedChallengesCount': FieldValue.increment(1),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Progress updated for '$challengeID'!")),
    );
  } catch (e) {
    debugPrint("❌ Failed to update challenge: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Error updating challenge")),
    );
  }
}
