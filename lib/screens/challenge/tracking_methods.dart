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
      setState(() {
        _progress = doc['progress'] ?? 0;
      });
    }
  }

  Future<void> _updateChallengeProgress(int newProgress) async {
    if (_user == null) return;

    bool isCompleted = newProgress >= widget.requiredProgress;

    await _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_${widget.challengeID}")
        .set({
      'userID': _user!.uid,
      'challengeID': widget.challengeID,
      'status': isCompleted ? 'completed' : 'in_progress',
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
    switch (widget.trackingMethod) {
      case "self_report":
        return ElevatedButton(
          onPressed: _handleSelfReport,
          child: const Text("Mark as Completed"),
        );

      case "photo_upload":
        return Column(
          children: [
            _image != null
                ? Image.file(_image!,
                    width: 200, height: 200, fit: BoxFit.cover)
                : const Text("No Image Selected"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handlePhotoUpload,
              child: const Text("Upload Photo"),
            ),
          ],
        );

      case "qr":
        return ElevatedButton(
          onPressed: _handleQRScan,
          child: const Text("Scan QR Code"),
        );

      case "manual_logging":
        return ElevatedButton(
          onPressed: _handleManualLogging,
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
