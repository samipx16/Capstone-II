import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  User? _user;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
        _nameController.text = user.displayName ?? "";
      });

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? "";
        });
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? "User",
          'email': user.email,
          'photoURL': user.photoURL ?? "",
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (_user != null) {
        DocumentReference userRef = _firestore.collection('users').doc(_user!.uid);
        DocumentSnapshot docSnapshot = await userRef.get();
        if (!docSnapshot.exists) {
          await userRef.set({
            'name': _nameController.text,
            'email': _user!.email,
            'photoURL': _user!.photoURL ?? "",
          });
        } else {
          await userRef.update({
            'name': _nameController.text,
          });
        }
        await _user!.updateDisplayName(_nameController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_image == null || _user == null) return;

    try {
      // Define storage path
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${_user!.uid}.jpg');

      // Start upload
      UploadTask uploadTask = storageRef.putFile(_image!);

      // Listen to upload status
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print("Upload Progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}");
      });

      // Wait for completion
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => print("Upload Completed"));

      // Get the download URL
      String downloadURL = await snapshot.ref.getDownloadURL();
      print("Download URL: $downloadURL");

      // Update Firestore with new photo URL
      DocumentReference userRef = _firestore.collection('users').doc(_user!.uid);
      DocumentSnapshot docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'name': _user!.displayName ?? "User",
          'email': _user!.email,
          'photoURL': downloadURL,
        });
      } else {
        await userRef.update({'photoURL': downloadURL});
      }

      // Update Firebase Auth profile photo
      await _user!.updatePhotoURL(downloadURL);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture updated successfully")),
      );
    } catch (e) {
      print("Error uploading picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading picture: $e")),
      );
    }
  }


  Future<void> _changePassword() async {
    String? currentPassword = await _showCurrentPasswordDialog();

    if (currentPassword == null || currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password update canceled")),
      );
      return;
    }

    if (_passwordController.text.isNotEmpty) {
      try {
        // Get the current user
        User? user = _auth.currentUser;
        if (user != null) {
          // Reauthenticate the user with the current password
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword, // User must enter this
          );

          await user.reauthenticateWithCredential(credential);

          // If reauthentication is successful, update the password
          await user.updatePassword(_passwordController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password updated successfully")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating password: $e")),
        );
      }
    }
  }
  Future<String?> _showCurrentPasswordDialog() async {
    TextEditingController currentPasswordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Reauthenticate"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter your current password to proceed."),
              TextField(
                controller: currentPasswordController,
                decoration: InputDecoration(labelText: "Current Password"),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Cancel
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, currentPasswordController.text);
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : null,
                child: _user?.photoURL == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Update Name"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text("Save Name"),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }
}
