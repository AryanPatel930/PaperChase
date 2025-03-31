import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _bioController = TextEditingController();
  File? _imageFile; // Stores the picked image file

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<DocumentSnapshot?> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _pickImage() async {
    var status = await Permission.photos.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied. Please enable access from settings.")),
      );
      return;
    }

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
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

    // Normally, this would upload the image to Firebase Storage. 
    // For now, we store the local file path in Firestore.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profile_image': _imageFile!.path,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile image uploaded successfully!")),
    );
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot?>(
          future: _loadUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading...");
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text("Profile Not Found");
            }

            var userDoc = snapshot.data!;
            String fullName = "${userDoc['first_name']} ${userDoc['last_name']}";

            return Text(
              fullName,
              style: TextStyle(
                fontFamily: 'Impact',
                fontSize: 24,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            );
          },
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? kDarkBackground : kLightBackground,
        ),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _loadUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile Not Found"));
          }

          var userDoc = snapshot.data!;
          String fullName = "${userDoc['first_name']} ${userDoc['last_name']}";

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ), // Show Full Name
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
                    foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Save Profile"),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
        selectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
        unselectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
        currentIndex: 0, // Highlight the "Inbox" tab
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          } else if (index == 1) {
            Navigator.pushNamed(context, '/post');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/inbox'); // Stay on the same page
          }
        },
      ),
    );
  }
}
