import 'package:flutter/material.dart';
import 'colors.dart'; // Ensure you have your color constants defined here

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the app is in dark mode
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
        color: isDarkMode ? kDarkBackground : kLightBackground,
      ),
        title: const Text(
          "Create Post",
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
      body: const Center(child: Text("Post Screen")),
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
            Navigator.pushNamed(context, '/post'); // Stay on the same page
          } else if (index == 2) {
            Navigator.pushNamed(context, '/inbox');
          }
        },
      ),
    );
  }
}