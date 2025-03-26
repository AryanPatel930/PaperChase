import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostBookPage extends StatefulWidget {
  @override
  _PostBookPageState createState() => _PostBookPageState();
}

class _PostBookPageState extends State<PostBookPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController isbnController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
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

Future<String?> fetchBookDescription(String isbn) async {
  final String url = "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn";

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['totalItems'] > 0) {
        return data['items'][0]['volumeInfo']['description'] ?? 'No description available';
      }
    }
  } catch (e) {
    print("Error fetching book details: $e");
  }
  return null; // Return null if no description is found
}

Future<String?> uploadImageToImgur(File imageFile) async {
  try {
    final uri = Uri.parse('https://api.imgur.com/3/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = '00caf989adf38fa'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      return jsonData['data']['link']; // The image URL from Imgur
    } else {
      print('Failed to upload image to Imgur');
      return null;
    }
  } catch (e) {
    print('Error uploading image: $e');
    return null;
  }
}

  // Function to upload book data to Firebase
  Future<bool> uploadBook() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false; // Ensure user is logged in

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await uploadImageToImgur(_imageFile!); 
        if (imageUrl == null) return false; // Upload and get URL
      }

      await FirebaseFirestore.instance.collection('books').add({
        'title': titleController.text,
        'author': authorController.text,
        'isbn': isbnController.text,
        'price': priceController.text,
        'description': descriptionController.text,
        'userId': user.uid, // 🔹 Save logged-in user's ID
        'imageUrl': imageUrl ?? "", // Optional image
      });
      return true;
    } catch(e) {
        print("Error uploading book: $e");
        return false; 
    }
  }

  // Function to handle book posting
  Future<void> _postBook() async {
  if (titleController.text.isEmpty ||
      priceController.text.isEmpty || isbnController.text.isEmpty ||
      authorController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All fields are required.'))
    );
    return;
  }

  String? description = await fetchBookDescription(isbnController.text);
  descriptionController.text = description ?? 'No description available';

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
