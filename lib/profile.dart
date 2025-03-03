import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _bioController = TextEditingController();
  String _profileImageUrl = "";
  String _studentId = "";
  String _fullName = "";
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      setState(() {
        _fullName = "${userDoc['first_name']} ${userDoc['last_name']}";
        _studentId = "h#${userDoc['student_id']}";
        _bioController.text = userDoc['bio'] ?? "";
        _profileImageUrl = userDoc['profile_image'] ?? "";
      });
    }
  }

  Future<void> _pickImage() async {
    var status = await Permission.photos.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied. Please enable access from settings.")),
      );
      return;
    }

    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _imageFile == null) return;

    // Normally, you would upload to Firebase Storage, but for now, we'll just store a placeholder path
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profile_image': _imageFile!.path,
    });

    setState(() {
      _profileImageUrl = _imageFile!.path;
    });
  }

  Future<void> _saveBio() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'bio': _bioController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_fullName)), // Show user's name
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? FileImage(File(_profileImageUrl))
                    : null,
                child: _profileImageUrl.isEmpty
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(_studentId, style: const TextStyle(fontSize: 16)), // Show Student ID
            const SizedBox(height: 10),
            TextField(
              controller: _bioController,
              maxLength: 256,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveBio,
              child: const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
