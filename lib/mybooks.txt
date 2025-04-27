import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'book_detail_page.dart';

class MyBooksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Get current user ID
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(iconTheme: IconThemeData(
        color: isDarkMode ? kDarkBackground : kLightBackground,
      ),
        title: const Text(
          "My Books",
          style: TextStyle(
            fontFamily: 'Impact', // Ensure "Impact" is available in your fonts
            fontSize: 24, // Adjust size as needed
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,),
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
