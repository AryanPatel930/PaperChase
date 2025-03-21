import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostPage extends StatefulWidget {
  const PostPage({Key? key}) : super(key: key);

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late XFile? _imageFile;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  
  // Default selected condition
  String _selectedCondition = 'Like New';

  @override
  void initState() {
    super.initState();
    _imageFile = null;
  }

  // Pick an image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
    });
  }

  // Capture an image from camera
  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _imageFile = image;
    });
  }

  void _postTextbook() {
    if (_imageFile != null && _titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      // Handle the post functionality here. For example, uploading the image and other details.
      print('Title: ${_titleController.text}');
      print('Description: ${_descriptionController.text}');
      print('Condition: $_selectedCondition');
      print('Price: ${_priceController.text}');
      print('Image Path: ${_imageFile!.path}');
      
      // Show confirmation after posting
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Textbook Posted!')),
      );
    } else {
      // If any required field is missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Page'),
      ),
      body: SingleChildScrollView( // Wrap everything in a scrollable view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile != null
                ? Image.file(
                    File(_imageFile!.path),
                    height: 250,
                    width: 250,
                    fit: BoxFit.cover,
                  )
                : const Text('No image selected.'),
            const SizedBox(height: 20),
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter the title of the textbook',
                ),
              ),
              const SizedBox(height: 20),

            // If an image has been picked, display it
            

            TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'Enter the price of the textbook',
                ),
              ),
              const SizedBox(height: 20),
            TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a brief description',
                ),
                
              ),
              const SizedBox(height: 20),
              const Text(
                'Condition',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedCondition,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCondition = newValue!;
                  });
                },
                items: <String>['Poor', 'Fair', 'Good', "Like New"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height:20),
            ElevatedButton(
              onPressed: _pickImageFromGallery,
              child: const Text('Pick Image from Gallery'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImageFromCamera,
              child: const Text('Take a Photo with Camera'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _postTextbook,
              child: const Text('Post Image'),
            ),
          ],
        ),
      ),
    )
    );
  }
}
