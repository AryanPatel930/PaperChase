import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostBookPage extends StatefulWidget {
  @override
  _PostBookPageState createState() => _PostBookPageState();
}

class _PostBookPageState extends State<PostBookPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController isbnController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  File? _imageFile;

  // Function to pick an image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
  final pickedFile = await ImagePicker().pickImage(source: source);
  if (pickedFile != null) {
    setState(() {
      _imageFile = File(pickedFile.path);
    });
    print('Image picked: ${_imageFile!.path}');
  } else {
    print('No image selected.');
  }
}


  // Function to upload book data to Firebase
  Future<bool> uploadBook() async {
  try {
    // Store book details in Firestore
    await FirebaseFirestore.instance.collection('books').add({
      'title': titleController.text,
      'description': descriptionController.text,
      'price': priceController.text,
      'isbn': isbnController.text,
      'author': authorController.text,
      'imageUrl': '', // Remove Firebase Storage dependency
      'createdAt': Timestamp.now(),
    });

    return true;
  } catch (e) {
    print('Error uploading book: $e');
    return false;
  }
}


  // Function to handle book posting
  Future<void> _postBook() async {
  if (titleController.text.isEmpty || descriptionController.text.isEmpty ||
      priceController.text.isEmpty || isbnController.text.isEmpty ||
      authorController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All fields are required.'))
    );
    return;
  }
  bool success = await uploadBook();
  if (success) {
    Navigator.pushReplacementNamed(context, '/mybooks');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to post book. Try again.'))
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post a Book')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 10),

              // Description Input
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 10),

              // Price Input
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),

              // ISBN Input
              TextField(
                controller: isbnController,
                decoration: InputDecoration(labelText: 'ISBN Number'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),

              // Author Input
              TextField(
                controller: authorController,
                decoration: InputDecoration(labelText: 'Author'),
              ),
              SizedBox(height: 20),

              // Image Picker Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera),
                    label: Text('Camera'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Display Selected Image
              if (_imageFile != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              SizedBox(height: 20),

              // Post Book Button
              Center(
                child: ElevatedButton(
                  onPressed: _postBook,
                  child: Text('Post Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
