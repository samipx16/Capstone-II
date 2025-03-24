import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // For random facts
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../qr_scanner_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/bottom_navbar.dart';
import 'package:confetti/confetti.dart';
import '../widgets/qr_helper.dart';

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
  int _currentIndex = 1;
  ConfettiController? _confettiController;
  String? _challengeTitle;
  String? _challengeDescription;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserChallengeProgress();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _loadUserChallengeProgress() async {
    if (_user == null) return;

    // Load progress from user_challenges
    DocumentSnapshot doc = await _firestore
        .collection('user_challenges')
        .doc("${_user!.uid}_${widget.challengeID}")
        .get();

    // Load challenge details (title, description) from challenges collection
    DocumentSnapshot challengeDoc =
        await _firestore.collection('challenges').doc(widget.challengeID).get();

    if (mounted) {
      setState(() {
        _progress = doc.exists
            ? (doc.data() as Map<String, dynamic>)['progress'] ?? 0
            : 0;

        if (challengeDoc.exists) {
          var challengeData = challengeDoc.data() as Map<String, dynamic>;
          _challengeTitle = challengeData['title'];
          _challengeDescription = challengeData['description'];
        }
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
      // Fetch existing document to check for `completedChallengesCount`
      DocumentSnapshot doc = await docRef.get();
      int existingCompletedCount = 0;

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        existingCompletedCount = data['completedChallengesCount'] ?? 0;
      }

      await docRef.set({
        'status': newStatus,
        'progress': newProgress,
        'lastUpdated': FieldValue.serverTimestamp(),
        'completedChallengesCount': isCompleted
            ? existingCompletedCount + 1
            : existingCompletedCount, // Increment count only when completed
      }, SetOptions(merge: true));

      //  If the challenge is completed, update lifetime points
      if (isCompleted) {
        await _updateLifetimePoints();
        _confettiController?.play();
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
      //  Fetch challenge points from the challenges collection
      DocumentSnapshot challengeDoc = await challengeDocRef.get();
      int challengePoints = 10; // Default points if not specified

      if (challengeDoc.exists) {
        var challengeData = challengeDoc.data() as Map<String, dynamic>;
        challengePoints = challengeData['points'] ??
            10; // Use the stored points or default to 10
      }

      // Fetch the user's current lifetime points
      DocumentSnapshot userDoc = await userDocRef.get();
      int currentLifetimePoints = 0;

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        currentLifetimePoints = userData['lifetimePoints'] ?? 0;
      }

      // Update Firestore with the new lifetime points
      await userDocRef.set({
        'lifetimePoints': currentLifetimePoints + challengePoints,
      }, SetOptions(merge: true));

      debugPrint(
          " Lifetime points updated: ${currentLifetimePoints + challengePoints}");
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
    final ImageSource? source = await _selectImageSource();
    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No image selected")),
      );
      return;
    }

    File imageFile = File(pickedFile.path);
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      //Upload image to Firebase Storage
      String fileName =
          "challenge_photos/${_user!.uid}_${widget.challengeID}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      //Load latest progress from Firestore
      final docRef = _firestore
          .collection('user_challenges')
          .doc("${_user!.uid}_${widget.challengeID}");
      DocumentSnapshot doc = await docRef.get();

      int currentProgress = 0;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentProgress = data['progress'] ?? 0;
      }

      int newProgress = currentProgress + 1;
      bool isCompleted = newProgress >= widget.requiredProgress;
      String newStatus = isCompleted ? "completed" : "in_progress";

      //Write all fields at once
      await docRef.set({
        'challengeID': widget.challengeID,
        'userID': _user!.uid,
        'photoUrl': imageUrl,
        'progress': newProgress,
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Confetti if completed
      if (isCompleted) {
        _confettiController?.play();
      }

      setState(() {
        _progress = newProgress;
        _image = imageFile;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Photo uploaded and progress saved!")),
      );
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
      setState(() {
        _isUploadingPhoto = false;
      });
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

        // Call Firestore update
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
            if (_isUploadingPhoto)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              )
            else if (_image != null)
              Image.file(_image!, width: 200, height: 200, fit: BoxFit.cover)
            else
              FutureBuilder<DocumentSnapshot>(
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
              onPressed:
                  isCompleted || _isUploadingPhoto ? null : _handlePhotoUpload,
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
        title: const Text(
          "Track Challenge",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Opacity(
                opacity: 0.20,
                child: Image.asset('assets/unt-logo.png'),
              ),
            ),
          ),
          if (_confettiController != null)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                maxBlastForce: 10,
                minBlastForce: 5,
                emissionFrequency: 0.1,
                gravity: 0.3,
                colors: const [Colors.green, Colors.lightGreen, Colors.white],
              ),
            ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_challengeTitle != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _challengeTitle!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _challengeDescription ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text("Progress: $_progress / ${widget.requiredProgress}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color.fromARGB(255, 112, 112, 112),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: _progress / widget.requiredProgress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
        ],
      ),
      // nav bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),

      //  QR scan button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );

          if (result != null) {
            await handleUniversalQRScan(context, result);
          }
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
