import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  String? _profilePictureUrl;
  String _name = '';
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user.uid).get();
      setState(() {
        _name = userDoc['name'] ?? 'No name';
        _profilePictureUrl = userDoc['profile_picture'];
      });
      _nameController.text = _name;
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _uploadImage(image);
    }
  }

  // Upload the picked image to Firebase Storage
  Future<void> _uploadImage(XFile image) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}.jpg');
      await storageRef.putFile(image.readAsBytes()! as File);
      String imageUrl = await storageRef.getDownloadURL();

      await _firestore.collection('Users').doc(user.uid).update({
        'profile_picture': imageUrl,
      });

      setState(() {
        _profilePictureUrl = imageUrl;
      });
    }
  }

  // Save name update
  Future<void> _saveName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('Users').doc(user.uid).update({
        'name': _nameController.text,
      });

      setState(() {
        _name = _nameController.text;
      });
    }
  }

  // Log out the user
  Future<void> _logOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profilePictureUrl != null
                    ? NetworkImage(_profilePictureUrl!)
                    : null,
                child: _profilePictureUrl == null
                    ? Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),
            SizedBox(height: 20),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            SizedBox(height: 20),

            // Save Name Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveName,
                child: Text('Save Name'),
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(double.infinity, 40)),
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Log Out Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logOut,
                child: Text('Log Out'),
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(Size(double.infinity, 40)),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
