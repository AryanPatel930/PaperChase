import 'package:flutter/material.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomFooter(
        currentIndex: currentIndex,
        toggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class CustomFooter extends StatelessWidget {
  final int currentIndex;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const CustomFooter({
    super.key,
    required this.currentIndex,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: isDarkMode ? Colors.white : Colors.black,
      selectedItemColor: isDarkMode ? Colors.black : Colors.white,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
      ],
      onTap: (index) {
        Navigator.pushReplacementNamed(context, ['/', '/post', '/inbox'][index]);
      },
    );
  }
}
