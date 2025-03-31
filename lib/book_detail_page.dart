import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookDetailsPage extends StatelessWidget {
  final Map<String, dynamic> book;

  BookDetailsPage({required this.book});

  @override
  Widget build(BuildContext context) {
    final title = book['title'] ?? 'No title available';
    final author = book['author'] ?? 'No author available';
    final isbn = book['isbn'] ?? 'No ISBN available';
    final price = book['price'] is String ? double.tryParse(book['price']) ?? 0.0 : book['price'] ?? 0.0;
    final condition = book['condition'] ?? 'Condition not available';
    final description = book['description'] ?? 'No description available';
    final imageUrl = book['imageUrl'] ?? 'https://via.placeholder.com/200'; // Fallback URL

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(  // Makes content scrollable
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, height: 200, fit: BoxFit.cover)
                    : Icon(Icons.book, size: 100),
              ),
              SizedBox(height: 20),
              Text("Title: $title", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("Author: $author", style: TextStyle(fontSize: 18)),
              Text("ISBN: $isbn", style: TextStyle(fontSize: 16)),
              Text("Price: \$${price.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, color: Colors.green)),
              Text("Condition: $condition", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Description:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(description, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
