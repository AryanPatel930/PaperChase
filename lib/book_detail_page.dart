import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot book;

  BookDetailsPage({required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book['title'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: book['imageUrl'] != null
                  ? Image.network(book['imageUrl'], height: 200, fit: BoxFit.cover)
                  : Icon(Icons.book, size: 100),
            ),
            SizedBox(height: 20),
            Text("Title: ${book['title']}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Author: ${book['author']}", style: TextStyle(fontSize: 18)),
            Text("ISBN: ${book['isbn']}", style: TextStyle(fontSize: 16)),
            Text("Price: \$${book['price']}", style: TextStyle(fontSize: 16, color: Colors.green)),
            SizedBox(height: 10),
            Text("Description:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(book['description'] ?? 'No description available', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
