import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() => _user = user);

      DocumentSnapshot doc =
      await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        setState(() {
          _firstNameController.text = doc['firstName'] ?? "";
          _lastNameController.text = doc['lastName'] ?? "";
        });
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': '',
          'lastName': '',
          'name': '',
          'email': user.email,
          'photoURL': user.photoURL ?? "",
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (_user != null) {
        String fullName =
            "${_firstNameController.text} ${_lastNameController.text}";
        DocumentReference userRef =
        _firestore.collection('users').doc(_user!.uid);

        DocumentSnapshot docSnapshot = await userRef.get();

        if (!docSnapshot.exists) {
          await userRef.set({
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
            'name': fullName,
            'email': _user!.email,
            'photoURL': _user!.photoURL ?? "",
          });
        } else {
          await userRef.update({
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
            'name': fullName,
          });
        }

        await _user!.updateDisplayName(fullName);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_image == null || _user == null) return;

    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${_user!.uid}.jpg');
      UploadTask uploadTask = storageRef.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      String downloadURL = await snapshot.ref.getDownloadURL();

      DocumentReference userRef =
      _firestore.collection('users').doc(_user!.uid);
      DocumentSnapshot docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'firstName': '',
          'lastName': '',
          'name': '',
          'email': _user!.email,
          'photoURL': downloadURL,
        });
      } else {
        await userRef.update({'photoURL': downloadURL});
      }

      await _user!.updatePhotoURL(downloadURL);

      setState(() {}); // refresh UI

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading picture: $e")),
      );
    }
  }

  Future<void> _changePassword() async {
    String? currentPassword = await _showCurrentPasswordDialog();

    if (currentPassword == null || currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password update canceled")),
      );
      return;
    }

    if (_passwordController.text.isNotEmpty) {
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );

          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_passwordController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password updated successfully")),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Incorrect current password.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating password: ${e.message}")),
          );
        }
      }
    }
  }

  Future<String?> _showCurrentPasswordDialog() async {
    TextEditingController currentPasswordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reauthenticate"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your current password to proceed."),
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(labelText: "Current Password"),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, currentPasswordController.text);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _user?.photoURL != null
                        ? NetworkImage(_user!.photoURL!)
                        : null,
                    child: _user?.photoURL == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.edit, size: 18, color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // First and Last Name Fields Together
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Update Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person, color: Colors.green),
                          hintText: "Enter First Name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.green),
                          hintText: "Enter Last Name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Save Name", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Password Section
              _buildSettingsCard(
                icon: Icons.lock,
                title: "Change Password",
                hintText: "Enter New Password",
                controller: _passwordController,
                onPressed: _changePassword,
                buttonText: "Change Password",
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String hintText,
    required TextEditingController controller,
    required VoidCallback onPressed,
    required String buttonText,
    bool obscureText = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.green),
                hintText: hintText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(buttonText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
