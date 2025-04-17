import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'colors.dart';
import 'NavBar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBackground : kLightBackground;
    final textColor = isDarkMode ? kDarkText : kLightText;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(color: textColor),
          ),
          backgroundColor: backgroundColor,
          iconTheme: IconThemeData(color: textColor),
        ),
        drawer: const NavBar(),
        body: Container(
          color: backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Please log in to view your profile',
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Log In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
        color: isDarkMode ? kDarkBackground : kLightBackground,
      ),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontFamily: 'Impact', // Ensure "Impact" is available in your fonts
            fontSize: 24, // Adjust size as needed
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,
        
        ),
      drawer: const NavBar(),
      body: Container(
        color: backgroundColor,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading profile',
                  style: TextStyle(color: textColor),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'Profile not found',
                  style: TextStyle(color: textColor),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final firstName = userData['first_name'] ?? '';
            final lastName = userData['last_name'] ?? '';
            final email = currentUser.email ?? '';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
                  child: Text(
                    '${firstName[0]}${lastName[0]}'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      color: isDarkMode ? kLightText : kDarkText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$firstName $lastName',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('books')
                      .where('userId', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, booksSnapshot) {
                    if (booksSnapshot.hasError) {
                      return Text(
                        'Error loading books',
                        style: TextStyle(color: textColor),
                      );
                    }

                    if (booksSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final books = booksSnapshot.data?.docs ?? [];

                    if (books.isEmpty) {
                      return Text(
                        'No books posted yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Books',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index].data() as Map<String, dynamic>;
                            return Card(
                              color: isDarkMode ? Colors.grey[900] : Colors.white,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  book['title'] ?? 'Untitled Book',
                                  style: TextStyle(color: textColor),
                                ),
                                subtitle: Text(
                                  book['description'] ?? 'No description',
                                  style: TextStyle(color: textColor.withOpacity(0.7)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  '\$${book['price']?.toString() ?? '0'}',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.green[300] : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/book_details',
                                    arguments: books[index].id,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
        selectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
        unselectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
        currentIndex: 0, // Highlight the "Post" tab
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