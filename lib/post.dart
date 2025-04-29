import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import
import 'colors.dart';

class PostBookPage extends StatefulWidget {
  const PostBookPage({super.key});

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
  String _selectedCondition = "Like New";
  final ImagePicker _picker = ImagePicker(); // Create a single instance

  // Function to request camera permission
  Future<bool> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  // Function to pick an image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permission if using camera
      if (source == ImageSource.camera) {
        bool hasPermission = await _requestCameraPermission();
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to take photos'))
          );
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Optimize image quality
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        print('Image picked: ${_imageFile!.path}');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'))
      );
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
      var request = http.MultipartRequest(
        'POST', Uri.parse('https://api.imgur.com/3/upload')
      );

      request.headers['Authorization'] = 'Client-ID 00caf989adf38fa';

      var pic = await http.MultipartFile.fromPath('image', imageFile.path);
      request.files.add(pic);

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['data']['link']; // Image URL from Imgur
      } else {
        print('Failed to upload image: ${response.reasonPhrase}');
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
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
        
        imageUrl = await uploadImageToImgur(_imageFile!); 
        
        // Hide loading indicator
        Navigator.of(context).pop();
        
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image. Please try again.'))
          );
          return false;
        }
      }

      await FirebaseFirestore.instance.collection('books').add({
        'title': titleController.text,
        'author': authorController.text,
        'isbn': isbnController.text,
        'price': priceController.text,
        'description': descriptionController.text,
        'condition': _selectedCondition,
        'userId': user.uid,
        'imageUrl': imageUrl ?? "",
        'timestamp': FieldValue.serverTimestamp(),
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
        const SnackBar(content: Text('All fields are required.'))
      );
      return;
    }

    // Show loading indicator while fetching description
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    String? description = await fetchBookDescription(isbnController.text);
    descriptionController.text = description ?? 'No description available';
    
    // Hide loading indicator
    Navigator.of(context).pop();

    bool success = await uploadBook();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book posted successfully!'))
      );
      Navigator.pushReplacementNamed(context, '/profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post book. Try again.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: isDarkMode ? kDarkBackground : kLightBackground,
        ),
        title: const Text(
          "Post a Book",
          style: TextStyle(
            fontFamily: 'Impact',
            fontSize: 24,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),

              // Price Input
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              // ISBN Input
              TextField(
                controller: isbnController,
                decoration: const InputDecoration(labelText: 'ISBN Number'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              // Author Input
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedCondition,
                items: ['Like New', 'Good', 'Fair', 'Poor']
                    .map((condition) => DropdownMenuItem(
                          value: condition,
                          child: Text(condition),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
                  });
                },
                dropdownColor: isDarkMode ? kDarkBackground : kLightBackground, 
                decoration: InputDecoration(
                  labelText: 'Condition',
                  filled: true,
                  fillColor: isDarkMode ? kDarkBackground : kLightBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),

              const SizedBox(height: 50),
              // Image Picker Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera, color: isDarkMode ? kLightText: kDarkText),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
                      foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: isDarkMode ? kLightText: kDarkText),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
                      foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Display Selected Image
              if (_imageFile != null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Post Book Button
              Center(
                child: ElevatedButton(
                  onPressed: _postBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
                    foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Post Book'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
        currentIndex: 1, // Highlight the "Post" tab
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
            Navigator.pushNamed(context, '/inbox');
          }
        },
      ),
    );
  }
}