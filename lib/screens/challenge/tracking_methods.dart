import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import '../qr_scanner_screen.dart';

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

      // ✅ Debugging Firestore data
      debugPrint("🔥 Loaded Firestore Data: ${data.toString()}");

      setState(() {
        _progress = data['progress'] ?? 0;
      });
    } else {
      debugPrint(
          "⚠️ No challenge progress found in Firestore for ${widget.challengeID}");
    }
  }

  Future<void> _updateChallengeProgress(int newProgress) async {
    if (_user == null) return;

    bool isCompleted = newProgress >= widget.requiredProgress;
    String newStatus = isCompleted ? 'completed' : 'in_progress';

    final docRef = _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_${widget.challengeID}");

    debugPrint("🚀 Attempting Firestore update:");
    debugPrint("Challenge ID: ${widget.challengeID}");
    debugPrint("New Progress: $newProgress");
    debugPrint("New Status: $newStatus");

    try {
      // Check if the document exists first
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        // Use update if the document already exists
        await docRef.update({
          'status': newStatus,
          'progress': newProgress,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create the document if it does not exist
        await docRef.set({
          'userID': _user!.uid,
          'challengeID': widget.challengeID,
          'status': newStatus,
          'progress': newProgress,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Optionally, read the document back to verify the update
      final updatedDoc = await docRef.get();
      debugPrint("✅ Updated Firestore document data: ${updatedDoc.data()}");

      setState(() {
        _progress = newProgress;
      });

      debugPrint("✅ Firestore update successful!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isCompleted ? "🎉 Challenge Completed!" : "📈 Progress Updated"),
        ),
      );
    } catch (e) {
      debugPrint("❌ Firestore update failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed: $e")),
      );
    }
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
    if (kIsWeb) {
      // Manually enter a QR code on web (Chrome)
      String? qrCode = await _showQRManualInputDialog();
      if (qrCode != null) {
        debugPrint("Manually Entered QR Code: $qrCode");
        _processQRCode(qrCode);
      }
    } else {
      // Mobile QR Scanner
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerScreen(),
        ),
      );
      if (result != null) {
        debugPrint("QR Code Scanned: $result");
        _processQRCode(result);
      }
    }
  }

// Function to show manual QR code input on Chrome
  Future<String?> _showQRManualInputDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController qrController = TextEditingController();
        return AlertDialog(
          title: const Text("Enter QR Code"),
          content: TextField(
            controller: qrController,
            decoration: const InputDecoration(hintText: "Enter QR Code"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, qrController.text),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

// Process the scanned or manually entered QR Code
  void _processQRCode(String qrCode) async {
    if (_user == null) return;

    debugPrint("🔍 Checking QR Code in Firestore: $qrCode");

    try {
      // Check if the QR Code exists in Firestore
      DocumentSnapshot binDoc =
          await _firestore.collection('recycling_bins').doc(qrCode).get();

      if (binDoc.exists) {
        debugPrint(
            "✅ QR Code Matched: $qrCode - ${binDoc['bin name']} at ${binDoc['location']}");

        // ✅ Call Firestore update
        await _updateChallengeProgress(_progress + 1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("✅ Scanned ${binDoc['bin name']} successfully!")),
        );
      } else {
        debugPrint("❌ No matching QR Code found in Firestore: $qrCode");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "❌ Invalid QR Code! This is not a valid recycling bin.")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Firestore error while checking QR Code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Error validating QR Code!")),
      );
    }
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
