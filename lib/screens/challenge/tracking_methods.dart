import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // For random facts
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import '../qr_scanner_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TrackingMethodsScreen extends StatefulWidget {
  final String challengeID;
  final String trackingMethod;
  final int requiredProgress;

  const TrackingMethodsScreen({
    super.key,
    required this.challengeID,
    required this.trackingMethod,
    required this.requiredProgress,
  });

  @override
  _TrackingMethodsScreenState createState() => _TrackingMethodsScreenState();
}

class _TrackingMethodsScreenState extends State<TrackingMethodsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;
  int _progress = 0;
  bool _isUpdating = false; // Prevent multiple clicks
  File? _image;
  String? _randomFact;
  final List<String> _sustainabilityFacts = [
    "Recycling one aluminum can saves enough energy to run a TV for 3 hours!",
    "Turning off your faucet while brushing your teeth can save 8 gallons of water per day.",
    "Plastic takes over 400 years to degrade in landfills.",
    "One tree can absorb as much carbon in a year as a car produces while driving 26,000 miles!",
    "LED bulbs use at least 75% less energy and last 25 times longer than traditional bulbs.",
  ];

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
      setState(() {
        _progress = data['progress'] ?? 0;
      });
    }
  }

  Future<void> _updateChallengeProgress(int newProgress) async {
    if (_user == null || _isUpdating) return;
    setState(() {
      _isUpdating = true;
    });

    bool isCompleted = newProgress >= widget.requiredProgress;
    String newStatus = isCompleted ? 'completed' : 'in_progress';

    final docRef = _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_${widget.challengeID}");

    try {
      await docRef.set({
        'status': newStatus,
        'progress': newProgress,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ If the challenge is completed, update the lifetime points
      if (isCompleted) {
        await _updateLifetimePoints();
      }

      setState(() {
        _progress = newProgress;
        _randomFact =
            _sustainabilityFacts[Random().nextInt(_sustainabilityFacts.length)];
        _isUpdating = false;
      });
    } catch (e) {
      debugPrint("❌ Firestore update failed: $e");
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _updateLifetimePoints() async {
    final userDocRef = _firestore.collection('users').doc(_user!.uid);
    final challengeDocRef =
        _firestore.collection('challenges').doc(widget.challengeID);

    try {
      // ✅ Fetch challenge points from the challenges collection
      DocumentSnapshot challengeDoc = await challengeDocRef.get();
      int challengePoints = 10; // Default points if not specified

      if (challengeDoc.exists) {
        var challengeData = challengeDoc.data() as Map<String, dynamic>;
        challengePoints = challengeData['points'] ??
            10; // Use the stored points or default to 10
      }

      // ✅ Fetch the user's current lifetime points
      DocumentSnapshot userDoc = await userDocRef.get();
      int currentLifetimePoints = 0;

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        currentLifetimePoints = userData['lifetimePoints'] ?? 0;
      }

      // ✅ Update Firestore with the new lifetime points
      await userDocRef.set({
        'lifetimePoints': currentLifetimePoints + challengePoints,
      }, SetOptions(merge: true));

      debugPrint(
          "✅ Lifetime points updated: ${currentLifetimePoints + challengePoints}");
    } catch (e) {
      debugPrint("❌ Failed to update lifetime points: $e");
    }
  }

  Future<void> _handleSelfReport() async {
    if (_user == null) return;

    debugPrint(
        "Self-report button pressed for Challenge: ${widget.challengeID}");

    await _updateChallengeProgress(widget.requiredProgress);
  }

  Future<void> _handlePhotoUpload() async {
    final picker = ImagePicker();

    // Ask user whether they want to use camera or gallery
    final ImageSource? source = await _selectImageSource();
    if (source == null) return; // User canceled the selection

    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      debugPrint("❌ No image selected");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No image selected")),
      );
      return;
    }

    File imageFile = File(pickedFile.path);
    String fileName =
        "challenge_photos/${_user!.uid}_${widget.challengeID}_${DateTime.now().millisecondsSinceEpoch}.jpg";
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference storageRef = storage.ref().child(fileName);

    try {
      // Upload image to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the image URL
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with image URL
      await _firestore
          .collection('user_challenges')
          .doc("${_user!.uid}_${widget.challengeID}")
          .set({
        'challengeID': widget.challengeID,
        'photoUrl': imageUrl, // Store URL in Firestore
        'status': 'completed',
        'progress': widget.requiredProgress,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update UI state
      setState(() {
        _image = imageFile;
      });

      debugPrint("✅ Image uploaded successfully: $imageUrl");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("✅ Photo uploaded and challenge completed!")),
      );
    } catch (e) {
      debugPrint("❌ Image upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }
  }

  /// Show a dialog for the user to pick between Camera or Gallery
  Future<ImageSource?> _selectImageSource() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choose Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Take a Photo"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleQRScan() async {
    if (kIsWeb) {
      // Manually enter a QR code on web
      String? qrCode = await _showQRManualInputDialog();
      if (qrCode != null) {
        debugPrint("Manually Entered QR Code: $qrCode");
        _processQRCode(qrCode);
      }
    } else {
      // Use the new MobileScanner
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
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
                : FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('user_challenges')
                        .doc("${_user!.uid}_${widget.challengeID}")
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text("No Image Uploaded");
                      }

                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      String? imageUrl = data['photoUrl'];

                      if (imageUrl != null) {
                        return Image.network(imageUrl,
                            width: 200, height: 200, fit: BoxFit.cover);
                      } else {
                        return const Text("No Image Uploaded");
                      }
                    },
                  ),
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
        title: const Text("Track Challenge"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text("Progress: $_progress / ${widget.requiredProgress}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: LinearProgressIndicator(
                value: _progress / widget.requiredProgress,
                backgroundColor: Colors.grey[300],
                color: Colors.green,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 Fix: Replace the generic button with the correct tracking method UI
            _buildTrackingUI(),

            if (_randomFact != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "🌱 Did You Know? $_randomFact",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
