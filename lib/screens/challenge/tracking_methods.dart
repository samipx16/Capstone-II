import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TrackingMethodsScreen extends StatefulWidget {
  final String challengeID;
  final String trackingMethod;
  final int requiredProgress;

  const TrackingMethodsScreen({
    Key? key,
    required this.challengeID,
    required this.trackingMethod,
    required this.requiredProgress,
  }) : super(key: key);

  @override
  _TrackingMethodsScreenState createState() => _TrackingMethodsScreenState();
}

class _TrackingMethodsScreenState extends State<TrackingMethodsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;
  int _progress = 0;
  File? _image;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserChallengeProgress();
  }

  Future<void> _loadUserChallengeProgress() async {
    if (_user == null) return;

    DocumentSnapshot doc = await _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_${widget.challengeID}")
        .get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? lastUpdated = data['lastUpdated'];

      DateTime today = DateTime.now();
      DateTime lastUpdateDate =
          lastUpdated?.toDate() ?? DateTime(2000); // Default to a long time ago

      bool isSameDay = today.year == lastUpdateDate.year &&
          today.month == lastUpdateDate.month &&
          today.day == lastUpdateDate.day;

      if (!isSameDay) {
        debugPrint(
            "Resetting challenge progress for ${widget.challengeID} as it's a new day.");
        await _firestore
            .collection('user_challenges')
            .doc("${_user!.uid}_${widget.challengeID}")
            .set({
          'progress': 0,
          'status': 'not_started',
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        setState(() {
          _progress = data['progress'] ?? 0;
        });
      }
    }
  }

  Future<void> _updateChallengeProgress(int newProgress) async {
    if (_user == null) return;

    bool isCompleted = newProgress >= widget.requiredProgress;
    String newStatus = isCompleted ? 'completed' : 'in_progress';

    debugPrint(
        "Updating challenge: ${widget.challengeID}, New Status: $newStatus, Progress: $newProgress");

    await _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_${widget.challengeID}")
        .set({
      'userID': _user!.uid,
      'challengeID': widget.challengeID,
      'status': newStatus,
      'progress': newProgress,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _progress = newProgress;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(isCompleted ? "Challenge Completed!" : "Progress Updated")),
    );
  }

  Future<void> _handleSelfReport() async {
    if (_user == null) return;

    debugPrint(
        "Self-report button pressed for Challenge: ${widget.challengeID}");

    await _updateChallengeProgress(widget.requiredProgress);
  }

  Future<void> _handlePhotoUpload() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      //Update Firestore Progress
      await _updateChallengeProgress(widget.requiredProgress);
    }
  }

  Future<void> _handleQRScan() async {
    await _updateChallengeProgress(_progress + 1);
  }

  Future<void> _handleManualLogging() async {
    if (_progress < widget.requiredProgress) {
      await _updateChallengeProgress(_progress + 1);
    }
  }

  Widget _buildTrackingUI() {
    debugPrint(
        "Tracking Method: ${widget.trackingMethod}, Progress: $_progress");

    bool isCompleted = _progress >= widget.requiredProgress;

    if (isCompleted) {
      return const Text(
        "✅ Challenge Completed!",
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
      );
    }

    switch (widget.trackingMethod) {
      case "Self Report":
        return ElevatedButton(
          onPressed: isCompleted ? null : _handleSelfReport,
          child: const Text("Mark as Completed"),
        );

      case "Photo Upload":
        return Column(
          children: [
            _image != null
                ? Image.file(_image!,
                    width: 200, height: 200, fit: BoxFit.cover)
                : const Text("No Image Selected"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isCompleted ? null : _handlePhotoUpload,
              child: const Text("Upload Photo"),
            ),
          ],
        );

      case "QR":
        return ElevatedButton(
          onPressed: isCompleted ? null : _handleQRScan,
          child: const Text("Scan QR Code"),
        );

      case "Manual Logging":
        return ElevatedButton(
          onPressed: isCompleted ? null : _handleManualLogging,
          child: const Text("Log Progress"),
        );

      default:
        return const Text("Tracking method not supported.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Track Challenge"), backgroundColor: Colors.green),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Progress: $_progress / ${widget.requiredProgress}"),
            const SizedBox(height: 20),
            _buildTrackingUI(),
          ],
        ),
      ),
    );
  }
}
