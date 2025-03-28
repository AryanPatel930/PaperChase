import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'book_detail_page.dart';

class MyBooksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get current user ID
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: Text("My Books")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('userId', isEqualTo: userId) // 🔹 Filter by logged-in user ID
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var books = snapshot.data!.docs;

          if (books.isEmpty) {
            return Center(child: Text("No books posted yet."));
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              var book = books[index].data() as Map<String, dynamic>;  // Use data() to get the map

              return ListTile(
                leading: book['imageUrl'] != null
                    ? Image.network(book['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(Icons.book),
                title: Text(book['title']),
                subtitle: Text(book['author']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsPage(book: book),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
