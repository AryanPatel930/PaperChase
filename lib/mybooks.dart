import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class MyBooksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Books')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('books').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No books found.'));
          }

          var books = snapshot.data!.docs;

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              var book = books[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(book['title'] ?? 'No Title'),
                subtitle: Text(book['author'] ?? 'Unknown Author'),
                trailing: Text("\$${book['price']}"),
              );
            },
          );
        },
      ),
    );
  }
}
