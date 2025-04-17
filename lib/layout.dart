import 'package:flutter/material.dart';
import 'package:paperchase_app/colors.dart';

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
      backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
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
